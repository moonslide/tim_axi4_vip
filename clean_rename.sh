#!/bin/bash

# Clean ULTRATHINK Test Renaming Script  
# Fix duplicate naming and complete all renaming properly

echo "========================================="
echo "Clean AXI4 VIP Test Renaming - ULTRATHINK"
echo "========================================="

# First, fix all the duplicate names that were created
echo "Step 1: Fixing duplicate names..."

# Fix double names back to single names
find . -name "*_sequential_mixed_ops_sequential_mixed_ops*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_sequential_mixed_ops_sequential_mixed_ops/_sequential_mixed_ops/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_concurrent_reads_concurrent_reads*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_concurrent_reads_concurrent_reads/_concurrent_reads/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_exclusive_write_success_exclusive_write_success*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_exclusive_write_success_exclusive_write_success/_exclusive_write_success/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_arlen_out_of_spec_arlen_out_of_spec*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_arlen_out_of_spec_arlen_out_of_spec/_arlen_out_of_spec/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_exclusive_read_success_exclusive_read_success*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_exclusive_read_success_exclusive_read_success/_exclusive_read_success/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_exclusive_write_fail_exclusive_write_fail*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_exclusive_write_fail_exclusive_write_fail/_exclusive_write_fail/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_wlast_too_early_wlast_too_early*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_wlast_too_early_wlast_too_early/_wlast_too_early/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_wid_awid_mismatch_wid_awid_mismatch*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_wid_awid_mismatch_wid_awid_mismatch/_wid_awid_mismatch/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_awlen_out_of_spec_awlen_out_of_spec*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_awlen_out_of_spec_awlen_out_of_spec/_awlen_out_of_spec/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_wlast_too_late_wlast_too_late*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_wlast_too_late_wlast_too_late/_wlast_too_late/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

find . -name "*_exclusive_read_fail_exclusive_read_fail*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_exclusive_read_fail_exclusive_read_fail/_exclusive_read_fail/g')
    mv "$file" "$new_file" 2>/dev/null
    echo "  Fixed: $(basename "$file") -> $(basename "$new_file")"
done

echo ""
echo "Step 2: Updating all internal references..."

# Create mapping for internal content updates
declare -A update_map=(
    ["tc_001"]="concurrent_reads"
    ["tc_002"]="concurrent_writes_raw"
    ["tc_003"]="sequential_mixed_ops"
    ["tc_004"]="concurrent_error_stress"
    ["tc_005"]="exhaustive_random_reads"
    ["tc_046"]="id_multiple_writes_same_awid"
    ["tc_047"]="id_multiple_writes_different_awid"
    ["tc_048"]="id_multiple_reads_same_arid"
    ["tc_049"]="id_multiple_reads_different_arid"
    ["tc_050"]="wid_awid_mismatch"
    ["tc_051"]="wlast_too_early"
    ["tc_052"]="wlast_too_late"
    ["tc_053"]="awlen_out_of_spec"
    ["tc_054"]="arlen_out_of_spec"
    ["tc_055"]="exclusive_write_success"
    ["tc_056"]="exclusive_write_fail"
    ["tc_057"]="exclusive_read_success"
    ["tc_058"]="exclusive_read_fail"
)

# Update all file contents and references
for old_pattern in "${!update_map[@]}"; do
    new_pattern="${update_map[$old_pattern]}"
    echo "  Updating references: $old_pattern -> $new_pattern"
    
    # Update content in all SystemVerilog files
    find . -name "*.sv" -o -name "*.svh" | while read -r file; do
        if file "$file" | grep -q "text"; then
            sed -i "s/${old_pattern}/${new_pattern}/g" "$file" 2>/dev/null
            
            # Also handle uppercase variants
            old_upper=$(echo "$old_pattern" | tr '[:lower:]' '[:upper:]')
            new_upper=$(echo "$new_pattern" | tr '[:lower:]' '[:upper:]')
            sed -i "s/${old_upper}/${new_upper}/g" "$file" 2>/dev/null
        fi
    done
done

# Update test lists
echo "  Updating test lists..."
for list_file in sim/synopsys_sim/*.list; do
    if [ -f "$list_file" ]; then
        for old_pattern in "${!update_map[@]}"; do
            new_pattern="${update_map[$old_pattern]}"
            sed -i "s/${old_pattern}/${new_pattern}/g" "$list_file" 2>/dev/null
        done
    fi
done

# Update Makefile
if [ -f "sim/synopsys_sim/Makefile" ]; then
    echo "  Updating Makefile..."
    for old_pattern in "${!update_map[@]}"; do
        new_pattern="${update_map[$old_pattern]}"
        sed -i "s/${old_pattern}/${new_pattern}/g" "sim/synopsys_sim/Makefile" 2>/dev/null
    done
fi

echo ""
echo "========================================="
echo "Clean renaming completed successfully!"
echo "========================================="
echo ""
echo "Summary of renamed tests:"
for old_pattern in "${!update_map[@]}"; do
    new_pattern="${update_map[$old_pattern]}"
    echo "  $old_pattern -> $new_pattern"
done