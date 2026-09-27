use std::time::Duration;

use super::SeekError;
use crate::common::{ChannelCount, SampleRate};
use crate::math::nz;
use crate::{Sample, Source};

/// An empty source.
#[derive(Debug, Default, Copy, Clone)]
pub struct Empty {
    channels: Option<ChannelCount>,
    sample_rate: Option<SampleRate>,
}

impl Empty {
    /// An empty source that immediately ends without ever returning a sample to
    /// play
    #[inline]
    pub const fn new() -> Self {
        Self {
            channels: None,
            sample_rate: None,
        }
    }

    /// An empty source with specific channels and sample rate.
    #[inline]
    pub const fn with_format(channels: ChannelCount, sample_rate: SampleRate) -> Self {
        Self {
            channels: Some(channels),
            sample_rate: Some(sample_rate),
        }
    }
}

impl Iterator for Empty {
    type Item = Sample;

    #[inline]
    fn next(&mut self) -> Option<Self::Item> {
        None
    }

    #[inline]
    fn size_hint(&self) -> (usize, Option<usize>) {
        (0, Some(0))
    }
}

impl ExactSizeIterator for Empty {}

impl Source for Empty {
    #[inline]
    fn current_span_len(&self) -> Option<usize> {
        Some(0)
    }

    #[inline]
    fn channels(&self) -> ChannelCount {
        self.channels.unwrap_or_else(|| nz!(1))
    }

    #[inline]
    fn sample_rate(&self) -> SampleRate {
        self.sample_rate.unwrap_or(crate::DEFAULT_SAMPLE_RATE)
    }

    #[inline]
    fn total_duration(&self) -> Option<Duration> {
        Some(Duration::ZERO)
    }

    #[inline]
    fn try_seek(&mut self, _: Duration) -> Result<(), SeekError> {
        Err(SeekError::NotSupported {
            underlying_source: std::any::type_name::<Self>(),
        })
    }
}
