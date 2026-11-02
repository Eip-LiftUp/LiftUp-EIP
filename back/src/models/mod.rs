//! Data models, plus a small helper shared by the response conversions.

use rust_decimal::{prelude::ToPrimitive, Decimal};

pub mod program;
pub mod user;
pub mod workout;

/// Converts an optional database `Decimal` to `f64` for JSON responses.
///
/// Returns `None` when there is no value, or when the conversion fails: an
/// unreadable value must not be silently shown as `0`. On failure a warning is
/// logged with the field name only, never the value (it can be health data).
pub fn decimal_to_f64(value: Option<Decimal>, field: &str) -> Option<f64> {
    // `and_then` runs the closure only when there is a value, and flattens the
    // `Option<Option<f64>>` that `map` would give.
    value.and_then(|decimal| {
        let converted = decimal.to_f64();
        if converted.is_none() {
            tracing::warn!(field, "could not convert a decimal to f64, returning null");
        }
        converted
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Given a normal decimal, when converted, then the `f64` value is returned.
    #[test]
    fn decimal_to_f64_converts_normal_value() {
        let weight = Decimal::new(7550, 2); // 75.50
        assert_eq!(decimal_to_f64(Some(weight), "weight_kg"), Some(75.5));
    }

    /// Given no value, when converted, then `None` is returned (not `0.0`).
    #[test]
    fn decimal_to_f64_keeps_none() {
        assert_eq!(decimal_to_f64(None, "weight_kg"), None);
    }

    /// Given zero, when converted, then `0.0` is kept: only unreadable values become `None`.
    #[test]
    fn decimal_to_f64_keeps_real_zero() {
        assert_eq!(decimal_to_f64(Some(Decimal::ZERO), "weight"), Some(0.0));
    }
}
