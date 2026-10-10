use std::io::{self, Read, Write};

use flow_ethos::{Address, Aspect, Layer};
use signal::{
    Answer, Contracted, Delivery, Dispatch, ExchangeLedger, ExchangeTracking, FrameCapacity,
    FrameReading, FrameWriting, Greeted, HandshakeReceipt, Restorable, Signal, Signalizable,
};
use signal_flow::{Bind_Data, Lock_Data, Query, Refusal, Response, Unknown_Data};

const FLOW_ID: &str = "flow-stand-in";

pub fn sender_address() -> Address {
    Address {
        aspect: Aspect::Psyche,
        topic: "sender-not-recorded".to_owned(),
        layer: Layer::Secondary,
    }
}

fn refusal_for_unknown_sender(lock: Lock_Data) -> Response {
    Response::Refused(Refusal::Unknown(Unknown_Data::Address(lock.sender)))
}

fn answer(query: Query) -> io::Result<Response> {
    match query {
        Query::Bind(_) => Ok(Response::Bound(FLOW_ID.to_owned())),
        Query::Identify(_) => Ok(Response::Identified(sender_address())),
        Query::Lock(lock) => Ok(refusal_for_unknown_sender(lock)),
        _ => Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "flow stand-in received a query outside the sender-unknown fixture",
        )),
    }
}

struct FirstByteReader<'a, R> {
    first: Option<u8>,
    inner: &'a mut R,
}

impl<R: Read> Read for FirstByteReader<'_, R> {
    fn read(&mut self, buffer: &mut [u8]) -> io::Result<usize> {
        if buffer.is_empty() {
            return Ok(0);
        }
        if let Some(first) = self.first.take() {
            buffer[0] = first;
            return Ok(1);
        }
        self.inner.read(buffer)
    }
}

fn read_dispatch<R: Read>(reader: &mut R) -> io::Result<Option<Dispatch<Query>>> {
    let mut first = [0_u8; 1];
    loop {
        match reader.read(&mut first) {
            Ok(0) => return Ok(None),
            Ok(1) => break,
            Ok(_) => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "one-byte read returned more than one byte",
                ));
            }
            Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
            Err(error) => return Err(error),
        }
    }

    let mut prefixed = FirstByteReader {
        first: Some(first[0]),
        inner: reader,
    };
    let frame = prefixed
        .read_frame(FrameCapacity::default())
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
    let bytes: Vec<u8> = frame.into();
    let dispatch = Signal::<Dispatch<Query>>::from(bytes)
        .restore()
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
    Ok(Some(dispatch))
}

fn write_delivery<W: Write>(writer: &mut W, delivery: &Delivery<Response>) -> io::Result<()> {
    let signal = delivery
        .signalize()
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
    writer
        .write_frame(&signal, FrameCapacity::default())
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))
}

/// Serve one typed Signal connection from greeting through its exchanges.
pub fn serve_connection<S: Read + Write>(stream: &mut S) -> io::Result<()> {
    let greeting = match read_dispatch(stream)? {
        Some(Dispatch::Greet(greeting)) => greeting,
        Some(_) | None => {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "flow stand-in expected the Signal greeting first",
            ));
        }
    };

    let receipt = Query::receipt(&greeting);
    let contract_matches = matches!(receipt, HandshakeReceipt::Greeted(_));
    write_delivery(stream, &Delivery::Greeted(receipt))?;
    if !contract_matches {
        return Ok(());
    }

    let mut exchanges = ExchangeLedger::default();
    exchanges
        .greet()
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, format!("{error:?}")))?;

    loop {
        let Some(dispatch) = read_dispatch(stream)? else {
            return Ok(());
        };

        match dispatch {
            Dispatch::Open(opening) => {
                exchanges.admit(opening.exchange).map_err(|error| {
                    io::Error::new(io::ErrorKind::InvalidData, format!("{error:?}"))
                })?;
                let response = answer(opening.query)?;
                write_delivery(
                    stream,
                    &Delivery::Answer(Answer {
                        exchange: opening.exchange,
                        response,
                    }),
                )?;
                exchanges.release(opening.exchange).map_err(|error| {
                    io::Error::new(io::ErrorKind::InvalidData, format!("{error:?}"))
                })?;
            }
            Dispatch::Abandon(exchange) => {
                exchanges.release(exchange).map_err(|error| {
                    io::Error::new(io::ErrorKind::InvalidData, format!("{error:?}"))
                })?;
            }
            Dispatch::Greet(_) => {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "flow stand-in received a second Signal greeting",
                ));
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use std::{io::{self, Write}, os::unix::net::UnixStream, thread};

    use flow_ethos::{Address, Aspect, Layer, Process, Recipient};
    use signal::{
        Contracted, Delivery, Dispatch, FrameCapacity, FrameReading, FrameWriting,
        HandshakeReceipt, Opening, Restorable, Signal, Signalizable,
    };
    use signal_flow::{Bind_Data, Lock_Data, Query, Response, Unknown_Data};

    use crate::{sender_address, serve_connection};

    fn request(
        stream: &mut UnixStream,
        dispatch: &Dispatch<Query>,
    ) -> io::Result<Delivery<Response>> {
        let signal = dispatch
            .signalize()
            .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
        stream
            .write_frame(&signal, FrameCapacity::default())
            .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
        let frame = stream
            .read_frame(FrameCapacity::default())
            .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
        let bytes: Vec<u8> = frame.into();
        Signal::<Delivery<Response>>::from(bytes)
            .restore()
            .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))
    }

    #[test]
    fn identifies_then_refuses_unknown_sender_without_changing_its_address() {
        let (mut client, mut server) = UnixStream::pair().expect("socket pair");
        let serving = thread::spawn(move || serve_connection(&mut server));

        let greeting =
            request(&mut client, &Dispatch::Greet(Query::greeting())).expect("greeting round trip");
        assert_eq!(
            greeting,
            Delivery::Greeted(HandshakeReceipt::Greeted(Query::contract_digest()))
        );

        let process = Process {
            pid: 41,
            started: 73,
        };
        let bound_address = Address {
            aspect: Aspect::Field,
            topic: "message".to_owned(),
            layer: Layer::Primary,
        };
        assert_eq!(
            request(
                &mut client,
                &Dispatch::Open(Opening {
                    exchange: 1,
                    query: Query::Bind(Bind_Data {
                        address: bound_address.clone(),
                        process: process.clone(),
                    }),
                }),
            )
            .expect("Bind round trip"),
            Delivery::Answer(signal::Answer {
                exchange: 1,
                response: Response::Bound("flow-stand-in".to_owned()),
            })
        );

        let sender = match request(
            &mut client,
            &Dispatch::Open(Opening {
                exchange: 2,
                query: Query::Identify(process),
            }),
        )
        .expect("Identify round trip")
        {
            Delivery::Answer(signal::Answer {
                exchange: 2,
                response: Response::Identified(sender),
            }) => sender,
            other => panic!("unexpected Identify response: {other:?}"),
        };
        assert_eq!(sender, sender_address());

        let recipient = Address {
            aspect: Aspect::Mind,
            topic: "nexus".to_owned(),
            layer: Layer::Secondary,
        };
        assert_eq!(
            request(
                &mut client,
                &Dispatch::Open(Opening {
                    exchange: 3,
                    query: Query::Lock(Lock_Data {
                        sender: sender.clone(),
                        recipient: Recipient::Address(recipient),
                    }),
                }),
            )
            .expect("Lock round trip"),
            Delivery::Answer(signal::Answer {
                exchange: 3,
                response: Response::Refused(signal_flow::Refusal::Unknown(Unknown_Data::Address(
                    sender
                ),)),
            })
        );

        drop(client);
        serving
            .join()
            .expect("stand-in thread joins")
            .expect("serve succeeds");
    }

    #[test]
    fn rejects_a_truncated_frame_instead_of_treating_it_as_clean_close() {
        let (mut client, mut server) = UnixStream::pair().expect("socket pair");
        let serving = thread::spawn(move || serve_connection(&mut server));

        assert_eq!(
            request(&mut client, &Dispatch::Greet(Query::greeting()))
                .expect("greeting round trip"),
            Delivery::Greeted(HandshakeReceipt::Greeted(Query::contract_digest()))
        );

        client
            .write_all(&[0, 0, 0, 2, 0x23])
            .expect("write incomplete frame");
        drop(client);

        let error = serving
            .join()
            .expect("stand-in thread joins")
            .expect_err("truncated frame must fail");
        assert_eq!(error.kind(), io::ErrorKind::InvalidData);
    }
}
