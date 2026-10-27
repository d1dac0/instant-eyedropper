//! Tests for the nearest named-color lookup (`names.rs`).

use super::*;

#[test]
fn test_exact_matches_return_their_name() {
    assert_eq!(nearest_name(0, 0, 0), "Black");
    assert_eq!(nearest_name(255, 255, 255), "White");
    assert_eq!(nearest_name(70, 130, 180), "Steel Blue");
    assert_eq!(nearest_name(255, 0, 0), "Red");
}

#[test]
fn test_near_miss_resolves_to_closest() {
    // Steel Blue ±1 per channel is still Steel Blue.
    assert_eq!(nearest_name(71, 131, 181), "Steel Blue");
    // A slightly off-white lands on a white family name.
    assert_eq!(nearest_name(254, 254, 254), "White");
}

#[test]
fn test_mid_gray_lands_on_gray_family() {
    let name = nearest_name(127, 127, 127);
    assert!(name.contains("Gray"), "127,127,127 resolved to {name}");
}

#[test]
fn test_table_is_sorted_and_rgb_unique() {
    // Names alphabetical; RGB values unique — both keep exact-match
    // resolution deterministic regardless of table order.
    let names: Vec<&str> = NAMED_COLORS.iter().map(|c| c.0).collect();
    let mut sorted = names.clone();
    sorted.sort_unstable();
    assert_eq!(names, sorted, "NAMED_COLORS must stay alphabetical");

    let mut rgbs: Vec<(u8, u8, u8)> = NAMED_COLORS.iter().map(|c| (c.1, c.2, c.3)).collect();
    let len_before = rgbs.len();
    rgbs.sort_unstable();
    rgbs.dedup();
    assert_eq!(
        len_before,
        rgbs.len(),
        "NAMED_COLORS has duplicate RGB values — exact matches become ambiguous"
    );
}

#[test]
fn test_lookup_covers_the_space() {
    // Every anchor color must resolve to itself: nearest(NC) == NC by
    // construction, but this pins the short-circuit and distance math.
    for &(name, r, g, b) in NAMED_COLORS {
        assert_eq!(nearest_name(r, g, b), name);
    }
}
