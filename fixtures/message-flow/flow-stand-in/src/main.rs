use std::{env, fs, io, os::unix::net::UnixListener, path::PathBuf};

use flow_stand_in::serve_connection;

fn socket_path() -> io::Result<PathBuf> {
    let mut arguments = env::args_os().skip(1);
    let Some(path) = arguments.next() else {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "usage: flow-stand-in SOCKET_PATH",
        ));
    };
    if arguments.next().is_some() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "flow-stand-in accepts one socket path",
        ));
    }
    Ok(path.into())
}

fn run() -> io::Result<()> {
    let path = socket_path()?;
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let listener = UnixListener::bind(&path)?;
    for connection in listener.incoming() {
        match connection {
            Ok(mut stream) => {
                if let Err(error) = serve_connection(&mut stream) {
                    eprintln!("flow-stand-in: {error}");
                }
            }
            Err(error) => eprintln!("flow-stand-in: accept failed: {error}"),
        }
    }
    Ok(())
}

fn main() {
    if let Err(error) = run() {
        eprintln!("flow-stand-in: {error}");
        std::process::exit(1);
    }
}
