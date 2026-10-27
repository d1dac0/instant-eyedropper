//! Embeds the tray/window icon into Windows builds as resource `1`
//! (what tray_win.rs loads via MAKEINTRESOURCE(1)). No-op elsewhere.

fn main() {
    println!("cargo:rerun-if-changed=assets/ie-r.ico");
    if std::env::var("CARGO_CFG_TARGET_OS").as_deref() == Ok("windows") {
        let mut res = winresource::WindowsResource::new();
        res.set_icon("assets/ie-r.ico");
        res.compile().expect("embed ie-r.ico as resource 1");
    }
}
