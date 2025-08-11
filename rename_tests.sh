#!/bin/bash

# ULTRATHINK Test Renaming Script
# Removes tc_0XX number patterns from test, sequence, and virtual sequence names

echo "======================================"
echo "AXI4 VIP Test Renaming - ULTRATHINK"
echo "======================================"

# Define renaming mappings
declare -A rename_map=(
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

# Function to rename files and update contents
rename_and_update() {
    local old_pattern=$1
    local new_pattern=$2
    
    echo "Processing: $old_pattern -> $new_pattern"
    
    # Find and rename files
    for file in $(find . -name "*${old_pattern}*" -type f | grep -E "\.(sv|svh)$"); do
        # Generate new filename
        new_file=$(echo "$file" | sed "s/${old_pattern}/${new_pattern}/g")
        
        # Update file contents before renaming
        # Replace class names, module names, and references
        sed -i "s/${old_pattern}/${new_pattern}/g" "$file"
        
        # Also handle uppercase variants in defines
        old_upper=$(echo "$old_pattern" | tr '[:lower:]' '[:upper:]')
        new_upper=$(echo "$new_pattern" | tr '[:lower:]' '[:upper:]')
        sed -i "s/${old_upper}/${new_upper}/g" "$file"
        
        # Rename the file
        if [ "$file" != "$new_file" ]; then
            mv "$file" "$new_file"
            echo "  Renamed: $file -> $new_file"
        fi
    done
    
    # Update references in all other files
    find . -name "*.sv" -o -name "*.svh" -o -name "*.list" | while read -r file; do
        # Skip binary files
        if file "$file" | grep -q "text"; then
            # Replace references
            sed -i "s/${old_pattern}/${new_pattern}/g" "$file" 2>/dev/null
            
            # Also handle uppercase variants
            old_upper=$(echo "$old_pattern" | tr '[:lower:]' '[:upper:]')
            new_upper=$(echo "$new_pattern" | tr '[:lower:]' '[:upper:]')
            sed -i "s/${old_upper}/${new_upper}/g" "$file" 2>/dev/null
        fi
    done
}

# Process all mappings
for old_pattern in "${!rename_map[@]}"; do
    new_pattern="${rename_map[$old_pattern]}"
    rename_and_update "$old_pattern" "$new_pattern"
done

echo ""
echo "======================================"
echo "Additional cleanup for consistency"
echo "======================================"

# Update any remaining references in test lists
for list_file in sim/synopsys_sim/*.list; do
    if [ -f "$list_file" ]; then
        echo "Updating test list: $list_file"
        for old_pattern in "${!rename_map[@]}"; do
            new_pattern="${rename_map[$old_pattern]}"
            sed -i "s/${old_pattern}/${new_pattern}/g" "$list_file"
        done
    fi
done

# Update Makefile if needed
if [ -f "sim/synopsys_sim/Makefile" ]; then
    echo "Updating Makefile references"
    for old_pattern in "${!rename_map[@]}"; do
        new_pattern="${rename_map[$old_pattern]}"
        sed -i "s/${old_pattern}/${new_pattern}/g" "sim/synopsys_sim/Makefile"
    done
fi

echo ""
echo "======================================"
echo "Renaming complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Review the changes"
echo "2. Run 'make clean' to clear old compiled files"
echo "3. Test compilation with sample tests"