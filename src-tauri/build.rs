use std::fs;
use std::path::Path;

fn main() {
    let icons_dir = "icons";
    fs::create_dir_all(icons_dir).ok();

    // Generate RGBA PNG icons
    let sizes = [32, 128];
    for size in sizes {
        let path = format!("{}/{}x{}.png", icons_dir, size, size);
        if !Path::new(&path).exists() || needs_update(&path) {
            generate_rgba_png(&path, size);
        }
    }

    // 128x128@2x
    let path = format!("{}/128x128@2x.png", icons_dir);
    if !Path::new(&path).exists() || needs_update(&path) {
        generate_rgba_png(&path, 128);
    }

    // icon.png
    let path = format!("{}/icon.png", icons_dir);
    if !Path::new(&path).exists() || needs_update(&path) {
        generate_rgba_png(&path, 512);
    }

    println!("cargo:rerun-if-changed=build.rs");
    tauri_build::build();
}

fn needs_update(path: &str) -> bool {
    // Check if file exists and is valid PNG
    if let Ok(data) = fs::read(path) {
        // PNG signature check
        data.len() > 8 && data[0..8] == [137, 80, 78, 71, 13, 10, 26, 10]
    } else {
        true
    }
}

fn generate_rgba_png(path: &str, size: u32) {
    // Create a simple RGBA PNG with cyan color (#00d2ff)
    let r = 0u8;
    let g = 210u8;
    let b = 255u8;
    let a = 255u8;

    // PNG signature
    let signature: [u8; 8] = [137, 80, 78, 71, 13, 10, 26, 10];

    // IHDR chunk
    let width_bytes = (size as u32).to_be_bytes();
    let height_bytes = (size as u32).to_be_bytes();
    let mut ihdr_data = Vec::new();
    ihdr_data.extend_from_slice(&width_bytes);
    ihdr_data.extend_from_slice(&height_bytes);
    ihdr_data.push(8);  // bit depth
    ihdr_data.push(6);  // color type: RGBA
    ihdr_data.push(0);  // compression
    ihdr_data.push(0);  // filter
    ihdr_data.push(0);  // interlace
    let ihdr = make_chunk(b"IHDR", &ihdr_data);

    // IDAT chunk - image data
    let mut raw_data = Vec::new();
    for _ in 0..size {
        raw_data.push(0); // filter type: None
        for _ in 0..size {
            raw_data.push(r);
            raw_data.push(g);
            raw_data.push(b);
            raw_data.push(a);
        }
    }

    // Compress with zlib
    let compressed = zlib_compress(&raw_data);
    let idat = make_chunk(b"IDAT", &compressed);

    // IEND chunk
    let iend = make_chunk(b"IEND", &[]);

    // Combine
    let mut png = Vec::new();
    png.extend_from_slice(&signature);
    png.extend_from_slice(&ihdr);
    png.extend_from_slice(&idat);
    png.extend_from_slice(&iend);

    fs::write(path, &png).expect("Failed to write icon PNG");
}

fn make_chunk(chunk_type: &[u8], data: &[u8]) -> Vec<u8> {
    let mut chunk = Vec::new();
    let len = (data.len() as u32).to_be_bytes();
    chunk.extend_from_slice(&len);
    chunk.extend_from_slice(chunk_type);
    chunk.extend_from_slice(data);
    let crc = crc32(chunk_type, data);
    chunk.extend_from_slice(&crc.to_be_bytes());
    chunk
}

fn crc32(chunk_type: &[u8], data: &[u8]) -> u32 {
    let mut crc: u32 = 0xFFFFFFFF;
    for &byte in chunk_type {
        crc = update_crc(crc, byte);
    }
    for &byte in data {
        crc = update_crc(crc, byte);
    }
    crc ^ 0xFFFFFFFF
}

fn update_crc(crc: u32, byte: u8) -> u32 {
    let mut c = crc ^ (byte as u32);
    for _ in 0..8 {
        if c & 1 != 0 {
            c = (c >> 1) ^ 0xEDB88320;
        } else {
            c >>= 1;
        }
    }
    c
}

fn zlib_compress(data: &[u8]) -> Vec<u8> {
    let mut result = Vec::new();
    let cmf: u8 = 0x78;
    let fcheck = 31 - ((cmf as u16 * 256) % 31) as u8;
    result.push(cmf);
    result.push(fcheck);
    result.push(0x01); // final stored block
    let len = data.len() as u16;
    result.extend_from_slice(&len.to_le_bytes());
    result.extend_from_slice(&(!len).to_le_bytes());
    result.extend_from_slice(data);
    let adler = adler32(data);
    result.extend_from_slice(&adler.to_be_bytes());
    result
}

fn adler32(data: &[u8]) -> u32 {
    let mut a: u32 = 1;
    let mut b: u32 = 0;
    const MOD: u32 = 65521;
    for &byte in data {
        a = (a + byte as u32) % MOD;
        b = (b + a) % MOD;
    }
    (b << 16) | a
}
