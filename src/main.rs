pub fn add(a: f64, b: f64) -> Result<f64, String> {
    let result = a + b;
    if result.is_finite() {
        Ok(result)
    } else {
        Err("Addition resulted in overflow or NaN".to_string())
    }
}

pub fn subtract(a: f64, b: f64) -> Result<f64, String> {
    let result = a - b;
    if result.is_finite() {
        Ok(result)
    } else {
        Err("Subtraction resulted in overflow or NaN".to_string())
    }
}

pub fn multiply(a: f64, b: f64) -> Result<f64, String> {
    let result = a * b;
    if result.is_finite() {
        Ok(result)
    } else {
        Err("Multiplication resulted in overflow or NaN".to_string())
    }
}

pub fn divide(a: f64, b: f64) -> Result<f64, String> {
    if b == 0.0 {
        return Err("Division by zero".to_string());
    }
    
    let result = a / b;
    if result.is_finite() {
        Ok(result)
    } else {
        Err("Division resulted in overflow or NaN".to_string())
    }
}

fn main() {
    println!("--- Simple Rust Calculator ---");

    match add(10.0, 5.0) {
        Ok(result) => println!("10.0 + 5.0 = {}", result),
        Err(e) => println!("Error: {}", e),
    }
    
    match divide(10.0, 0.0) {
        Ok(result) => println!("10.0 / 0.0 = {}", result),
        Err(e) => println!("Error: {}", e),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    // POSITIVE / FUNCTIONAL TESTS
    #[test]
    fn test_add_positive() {
        assert_eq!(add(2.0, 3.0), Ok(5.0));
    }

    #[test]
    fn test_subtract_positive() {
        assert_eq!(subtract(10.0, 4.0), Ok(6.0));
    }

    #[test]
    fn test_multiply_positive() {
        assert_eq!(multiply(3.5, 2.0), Ok(7.0));
    }

    #[test]
    fn test_divide_positive() {
        assert_eq!(divide(15.0, 3.0), Ok(5.0));
    }

    #[test]
    fn test_add_negative_values() {
        assert_eq!(add(-5.0, -5.0), Ok(-10.0));
    }

    // NEGATIVE / EDGE CASE TESTS
    #[test]
    fn test_divide_by_zero_negative() {
        assert_eq!(divide(10.0, 0.0), Err("Division by zero".to_string()));
    }

    #[test]
    fn test_add_overflow_negative() {
        assert_eq!(add(f64::MAX, f64::MAX), Err("Addition resulted in overflow or NaN".to_string()));
    }

    #[test]
    fn test_subtract_underflow_negative() {
        assert_eq!(subtract(f64::MIN, f64::MAX), Err("Subtraction resulted in overflow or NaN".to_string()));
    }

    #[test]
    fn test_multiply_overflow_negative() {
        assert_eq!(multiply(f64::MAX, 2.0), Err("Multiplication resulted in overflow or NaN".to_string()));
    }
    
    #[test]
    fn test_nan_handling_negative() {
        assert_eq!(add(f64::NAN, 5.0), Err("Addition resulted in overflow or NaN".to_string()));
    }
}