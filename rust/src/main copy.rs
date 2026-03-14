use rodio::{source::Source, Decoder};
use realfft::{num_complex::Complex, RealFftPlanner, RealToComplex};
use std::io::BufReader;
use std::time::{Duration, Instant};
use std::{fs::File, num::NonZero};
const FFT_SIZE: usize = 1024;
use std::sync::Arc;

fn compute_waveform_from_pcm(
    pcm: &[f32],
    channels: usize,
    expected_chunks: usize,
    sample_stride: usize,
) -> Vec<f32> {
    let channels = channels.max(1);
    let sample_stride = sample_stride.max(1);
    let total_frames = pcm.len() / channels;

    if total_frames == 0 {
        return vec![0.0; expected_chunks];
    }

    let mut result = Vec::with_capacity(expected_chunks);

    for chunk_index in 0..expected_chunks {
        let start_frame = chunk_index * total_frames / expected_chunks;
        let end_frame = (chunk_index + 1) * total_frames / expected_chunks;

        let mut current_chunk_max = 0.0f32;
        let mut frame_idx = start_frame;

        while frame_idx < end_frame {
            let sample_idx = frame_idx * channels;
            for ch in 0..channels {
                let abs_sample = pcm[sample_idx + ch].abs();
                if abs_sample > current_chunk_max {
                    current_chunk_max = abs_sample;
                }
            }
            frame_idx += sample_stride;
        }

        result.push(current_chunk_max.min(1.0));
    }

    result
}



pub fn extract_loaded_waveform(
    expected_chunks: usize,
    sample_stride: usize,
) -> Result<Vec<f32>, String> {
    if expected_chunks == 0 {
        return Err("expected_chunks must be > 0".to_string());
    }

    let sample_stride = sample_stride.max(1);

    // No cache yet: decode the full file into memory in one shot (non-streaming).
    let file = File::open("e:/test.m4a").expect("找不到音频文件");
    let source = Decoder::try_from(file).map_err(|e| format!("decode failed: {}", e))?;
    let channels = source.channels().get() as usize;
    let pcm: Vec<f32> = source.collect();

    Ok(compute_waveform_from_pcm(
        &pcm,
        channels,
        expected_chunks,
        sample_stride,
    ))
}






struct FftSource<S>
where
    S: Source<Item = f32>,
{
    inner: S,
    fft: Arc<dyn RealToComplex<f32>>,
    input_buffer: Vec<f32>,
    output_buffer: Vec<Complex<f32>>,
    index: usize,
}

impl<S> FftSource<S>
where
    S: Source<Item = f32>,
{
    fn new(inner: S) -> Self {
        let mut planner = RealFftPlanner::<f32>::new();
        let fft = planner.plan_fft_forward(FFT_SIZE);

        Self {
            inner,
            input_buffer: fft.make_input_vec(),
            output_buffer: fft.make_output_vec(),
            fft,
            index: 0,
        }
    }

    fn compute_fft(&mut self) {
        if self
            .fft
            .process(&mut self.input_buffer, &mut self.output_buffer)
            .is_err()
        {
            return;
        }

        let spectrum: Vec<f32> = self
            .output_buffer
            .iter()
            .take(FFT_SIZE / 2)
            .map(|c| (c.re * c.re + c.im * c.im).sqrt())
            .collect();

        println!("FFT bins: {}", spectrum.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(","));
    }
}

impl<S> Iterator for FftSource<S>
where
    S: Source<Item = f32>,
{
    type Item = f32;

    fn next(&mut self) -> Option<Self::Item> {
        let sample = self.inner.next()?;

        self.input_buffer[self.index] = sample;

        self.index += 1;

        if self.index == FFT_SIZE {
            self.compute_fft();
            self.index = 0;
        }

        Some(sample)
    }
}

impl<S> Source for FftSource<S>
where
    S: Source<Item = f32>,
{
    fn current_span_len(&self) -> Option<usize> {
        self.inner.current_span_len()
    }

    fn channels(&self) -> NonZero<u16> {
        self.inner.channels()
    }

    fn sample_rate(&self) -> NonZero<u32> {
        self.inner.sample_rate()
    }

    fn total_duration(&self) -> Option<Duration> {
        self.inner.total_duration()
    }
}

fn main() {
    let start = Instant::now();
    extract_loaded_waveform(200, 10);
    let duration = start.elapsed();

    println!("代码执行耗时: {:?}", duration);
}

/* 
fn main() {
    // _stream must live as long as the sink
    let handle = rodio::DeviceSinkBuilder::open_default_sink().expect("open default audio stream");
    let player = rodio::Player::connect_new(&handle.mixer());

    let file = File::open("e:/test.m4a").expect("找不到音频文件");

    let source = Decoder::new(BufReader::new(file)).expect("解码失败");
    let fft_source = FftSource::new(source);
    
    player.append(fft_source);
    // The sound plays in a separate thread. This call will block the current thread until the
    // player has finished playing all its queued sounds.
    player.sleep_until_end();
}


 */

