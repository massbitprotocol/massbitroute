extern crate bindgen;
extern crate gcc;
use std::path::PathBuf;

fn main() {
    let path = PathBuf::from("src");

    // build時に毎回実行されるのでコメントアウト
    // expand_headers("binding.rs");
}

fn expand_headers(generated: &str) {
    let path = PathBuf::from("src");

    let bindings = bindgen::Builder::default()
        .header("src/wrapper.h")
        .generate()
        .expect("bindgen失敗");

    bindings
        .write_to_file(path.join(generated))
        .expect("ファイル書き込み失敗");
}
