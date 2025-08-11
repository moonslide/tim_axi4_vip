#!/bin/bash

# ULTRATHINK Test Rename Fix Script
# Fix double-naming issue from previous rename

echo "========================================"
echo "AXI4 VIP Test Rename Fix - ULTRATHINK"
echo "========================================"

# Revert double names back to correct single names
find . -name "*_id_multiple_writes_same_awid_id_multiple_writes_same_awid*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_id_multiple_writes_same_awid_id_multiple_writes_same_awid/_id_multiple_writes_same_awid/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Fixed: $file -> $new_file"
    fi
done

find . -name "*_id_multiple_writes_different_awid_id_multiple_writes_different_awid*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_id_multiple_writes_different_awid_id_multiple_writes_different_awid/_id_multiple_writes_different_awid/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Fixed: $file -> $new_file"
    fi
done

find . -name "*_id_multiple_reads_same_arid_id_multiple_reads_same_arid*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_id_multiple_reads_same_arid_id_multiple_reads_same_arid/_id_multiple_reads_same_arid/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Fixed: $file -> $new_file"
    fi
done

find . -name "*_id_multiple_reads_different_arid_id_multiple_reads_different_arid*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_id_multiple_reads_different_arid_id_multiple_reads_different_arid/_id_multiple_reads_different_arid/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Fixed: $file -> $new_file"
    fi
done

find . -name "*_concurrent_error_stress_concurrent_error_stress*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_concurrent_error_stress_concurrent_error_stress/_concurrent_error_stress/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Fixed: $file -> $new_file"
    fi
done

find . -name "*_exhaustive_random_reads_exhaustive_random_reads*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_exhaustive_random_reads_exhaustive_random_reads/_exhaustive_random_reads/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"
        echo "Fixed: $file -> $new_file"
    fi
done

find . -name "*_concurrent_writes_raw_concurrent_writes_raw*" -type f | while read file; do
    new_file=$(echo "$file" | sed 's/_concurrent_writes_raw_concurrent_writes_raw/_concurrent_writes_raw/g')
    if [ "$file" != "$new_file" ]; then
        mv "$file" "$new_file"  
        echo "Fixed: $file -> $new_file"
    fi
done

echo "Duplicated names fixed!"