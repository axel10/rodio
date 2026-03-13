import os

with open('rust/src/api/simple.rs', 'r') as f:
    text = f.read()

new_fn = """
pub fn extract_loaded_waveform(expected_chunks: usize) -> Result<Vec<f32>, String> {
    let path = {
        if let Ok(c) = controller().lock() {
            c.loaded_path.clone()
        } else {
            None
        }
    }.ok_or_else(|| "No loaded audio file to extract waveform from".to_string())?;

    let file = File::open(&path).map_err(|e| format!("open file failed: {} - {}", path, e))?;
    let source = Decoder::try_from(file).map_err(|e| format!("decode failed: {}", e))?;

    let total_samples = match source.total_duration() {
        Some(dur) => {
            let sample_rate: u32 = source.sample_rate().into();
            let channels: u16 = source.channels().into();
            (dur.as_millis() as u64 * sample_rate as u64 / 1000 * channels as u64) as usize
        }
        None => {
            let sample_rate: u32 = source.sample_rate().into();
            let channels: u16 = source.channels().into();
            3 * 60 * sample_rate as usize * channels as usize
        }
    };

    let samples_per_chunk = (total_samples / expected_chunks).max(1);

    let mut result = Vec::with_capacity(expected_chunks);
    let mut current_chunk_max = 0.0f32;
    let mut samples_in_chunk = 0usize;

    for sample in source {
        let abs_sample = sample.abs();
        if abs_sample > current_chunk_max {
            current_chunk_max = abs_sample;
        }
        samples_in_chunk += 1;

        if samples_in_chunk >= samples_per_chunk {
            result.push(current_chunk_max.min(1.0));
            samples_in_chunk = 0;
            current_chunk_max = 0.0;
        }
    }

    if samples_in_chunk > 0 {
        result.push(current_chunk_max.min(1.0));
    }

    Ok(result)
}
"""

with open('rust/src/api/simple.rs', 'a', encoding='utf-8') as f:
    f.write("\n" + new_fn)
