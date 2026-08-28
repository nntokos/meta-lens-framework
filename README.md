# VR Measurements

## Preparing input data
Each experiment directory needs one `.txt` file (laps/annotations) and one `.log` file (adb log) before preprocessing. Helpers to produce these from raw sources:

- **Laps annotations from a Google Sheet export**: if laps/annotations were recorded in a shared spreadsheet and exported to CSV (with an `App Name` column plus one column per annotator), split it into a per-annotator `.txt` file per app:
  ```
  python3 file_converters/laps_csv_to_txt.py <path_to_exported_csv> --output_dir ./_data
  ```
  Edit the `annotations` dict in `file_converters/laps_csv_to_txt.py` to match your annotator column names. Then place the generated `.txt` file(s) alongside the matching `.log` file in each experiment directory.

- **Merge multiple `summary.xlsx` files** (e.g. one per experiment) into a single combined Excel file:
  ```
  python3 file_converters/concat_xlsx_files.py /path/to/parent_dir --names summary.xlsx --output_file ./combined.xlsx
  ```

## Steps to run
1. Ensure the directory structure contains the following:
   - A directory with:
     - One `.txt` file
     - One `.log` file

2. **For a single directory**
   1. **Preprocess** with the following command
   ```
   scripts/preprocess_dir.sh /path/to/_data
   ```
   2. **Generate graphs** with the following command:
   ```
   scripts/graph_dir.sh /path/to/_data
   ```

4. For multiple directories
   1. **Preprocess** all directories with the following command:
   ```
   scripts/multi_preprocess_dir.sh /path/to/parent_dir
   ```
   2. **Generate graphs** for all directories with the following command:
   ```
   scripts/multi_graph_dir.sh /path/to/parent_dir
   ```

5. After the above have been executed there have been created files necessary to run scripts like:
- `scripts/analysis_script_runner.sh --imx471_spikes_csv`
- `scripts/analysis_script_runner.sh --umount_log_to_sleep_log`
- etc.
    </br>And all their multi versions.

## Sensor activity extraction
To extract raw sensor activity intervals (per-sensor start/stop events) from a preprocessed `adb_log*.csv` file, using the sensor definitions in `analyze/dict.json`:
```
python3 analyze/extract_sensor_activity.py /path/to/adb_log.csv --output sensor_activity.csv
```
Options:
- `--dict_file` — path to the sensor parsing-conditions JSON (default: `analyze/dict.json`)
- `--output` — output CSV path (default: `sensor_activity.csv` next to the input file)
- `--print_sensors <names|all>` — comma-separated sensor names to also print to console
- `--start_time` — override the start time used to compute relative timestamps (default: earliest time in the log)
- `--sort_by_time` — sort output by time only, instead of by sensor then time

## CDF extractions
>To run the below preprocessing and graphing commands, preprocessing and graphing must have been executed first.

For all the following, you can use:
- For a single directory:
  ```
  scripts/analysis_script_runner.sh /path/to/experiment_dir [OPTIONS]
  ```
- For multiple directories:
  ```
  scripts/multi_analysis_script_runner.sh /path/to/parent_dir [OPTIONS]
  ```
Where `[OPTIONS]` can be one or more of:
- `--umount_sleep_pt` (hmd unmount & sleep to pt activation durations)
- `--umount_sleep_imx471` (hmd umount & sleep to imx471 activation durations)
- `--umount_to_sleep` (hmd umount to sleep duration)
- `--umount_lap_to_sleep_lap` (hmd umount lap to sleep lap duration)
- `--umount_log_to_lap` (hmd umount log to lap duration)
- `--umount_lap_to_sleep_log` (hmd umount lap to sleep log duration)
- `--umount_log_to_sleep_log` (hmd umount log to sleep log duration)
- `--imx471_spikes_csv` (imx471 spikes)

After running the above, concatenate the results and generate CDFs:

- Concatenate CSVs:
  ```
  python3 ./scripts/concat_multi_dir_csvs.py /path/to_super_parent_dir '<csv_filename>' /path/to_super_parent_dir/'<csv_filename_combined>'
  ```
  Where `<csv_filename>` is the file to search for recursively (glob pattern, e.g. `hmd_umount_sleep_pt_durations.csv`) and `<csv_filename_combined>` is the path to write the concatenated output to (e.g. `hmd_umount_sleep_pt_durations_combined.csv`).

  `<csv_filename>` is the per-directory output file name for the selected option, e.g.:
    - `hmd_umount_sleep_pt_durations.csv`
    - `hmd_umount_sleep_imx471_durations.csv`
    - `hmd_umount_to_sleep_durations.csv`
    - `hmd_umount_lap_to_sleep_lap_durations.csv`
    - `hmd_umount_log_to_lap_durations.csv`
    - `hmd_umount_lap_to_sleep_log_durations.csv`
    - `hmd_umount_log_to_sleep_log_durations.csv`
    - `imx471_spikes.csv`

- Generate CDFs:
  ```
  python3 analyze/cdfs/generate_durations_cdf.py [CDF_OPTIONS] [--graphing_tool <matplotlib|plotly|both>] [--export_stats] [--combine_graph] [--output <output_path>]
  ```
  Where [CDF_OPTIONS] can be one or more of:
    - `--umount_sleep_pt <csv> <unmount_pt_start|pt_stop_sleep|all>`
    - `--umount_sleep_imx471 <csv> <unmount_imx471_start|imx471_stop_sleep|all>`
    - `--umount_to_sleep <csv1> [<csv2> ...]`
    - `--umount_lap_to_sleep_lap <csv1> [<csv2> ...]`
    - `--umount_log_to_lap <csv1> [<csv2> ...]`
    - `--umount_lap_to_sleep_log <csv1> [<csv2> ...]`
    - `--umount_log_to_sleep_log <csv1> [<csv2> ...]`
    # (add more as supported)

  Example:
  ```
  python3 analyze/cdfs/generate_durations_cdf.py \
    --umount_sleep_pt experiments/hmd_umount_sleep_pt_durations_combined.csv all \
    --umount_lap_to_sleep_lap experiments/hmd_umount_lap_to_sleep_lap_durations_combined.csv \
    --graphing_tool matplotlib --export_stats
  ```
    
---

### Example: Full CDF Extraction Procedure
```bash
# 1. Preprocess all experiment directories
scripts/multi_preprocess_dir.sh experiments
# 2. Generate graphs for all experiment directories
scripts/multi_graph_dir.sh experiments
# 3. Extract durations for all experiment directories (choose your option, e.g. --umount_sleep_pt)
scripts/multi_analysis_script_runner.sh experiments --umount_sleep_pt
# 4. Concatenate all resulting CSVs
python3 scripts/concat_multi_dir_csvs.py experiments hmd_umount_sleep_pt_durations.csv experiments/hmd_umount_sleep_pt_durations_combined.csv
# This creates: experiments/hmd_umount_sleep_pt_durations_combined.csv
# 5. Generate the CDF plot and stats
python3 analyze/cdfs/generate_durations_cdf.py \
    --umount_sleep_pt experiments/hmd_umount_sleep_pt_durations_combined.csv all \
    --graphing_tool matplotlib --export_stats
# Output: CDF plot and stats in the same directory
```
# You can repeat the above with any of the available options and corresponding CDF scripts/CSV names.

## Energy / CPU / GPU summaries
If experiment directories contain `ovr_metrics.csv` files (from the Meta OVR Metrics Tool), summarize the mean of one or more columns over the first N seconds of each file:
```
python3 scripts/ovr_metrics_summary.py /path/to/parent_dir --columns power_wattage,cpu_utilization_percentage,gpu_utilization_percentage
```
This recursively finds every `ovr_metrics.csv` under the root directory and writes a single summary CSV (default: `<root>/ovr_metrics_summary.csv`). Use `--columns all` to average every column, and `--output`, `--filename`, `--timestamp-column`, `--time-window` to override the defaults (see `--help`).

## Publication-quality activity graphs
`scripts/graph_dir.sh` (used in **Steps to run**) produces an interactive Plotly graph per experiment for day-to-day inspection. For static, LaTeX-styled multi-panel figures (e.g. for a paper), plot one or more preprocessed `adb_log*.csv` files together with `analyze/multi_graph_matplotlib_refined.py`:
```
python3 analyze/multi_graph_matplotlib_refined.py /path/to/adb_log1.csv [/path/to/adb_log2.csv ...] \
  --user_events /path/to/annotated_events.json --output activity_graph.png \
  --remove_title --stack vertical --legend_position 'upper center'
```
It supports excluding/relabeling attributes (`--exclude_attributes`), grouping subplots' shared axes (`--axis_groups_x`/`--axis_groups_y`), tiling instead of stacking (`--tile`), and saving each subplot to a separate file (`--save_each_subplot --output_filenames a.png;b.png;...`). See `--help` for the full option list.

## Commands for `adb`
- **Clear the logs**
   ```
   adb logcat -c
   ```

- **Collect logs**
   - **Mac/Linux**:
     ```
     adb logcat -d > adb_log_$(date +"%Y-%m-%d_%H-%M-%S")_<appname>.log
     ```
   - **Windows**:
     ```
     adb logcat -d *> adb_log_%date:~10,4%-%date:~4,2%-%date:~7,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%_<appname>.log
     ```
     or
     ```
     adb logcat -d > adb_log_%date:~6,4%-%date:~0,2%-%date:~3,2%_%time:~0,2%-%time:~3,2%-%time:~6,2%_abc.log 2>&1
     ```

   **Example Filename**: `adb_log_2025-03-06_11-57-19.log`

- **Pull Videos**
   ```
   adb pull /storage/self/primary/Oculus/VideoShots
   ```

- **Delete Videos from Device**
   ```
   adb shell "rm -rf /storage/self/primary/Oculus/VideoShots"
   ```

- **Wireless `adb` Debugging**
   1. **Connect the device through USB**  
   2. **Retrieve the device IP**:  
      ```
      adb shell ip route
      ```
      Look for the IP address listed after `src`.

   3. **Enable Wireless Debugging**:  
      ```
      adb tcpip 5555
      adb connect <ipaddress>:5555
      ```
      Replace `<ipaddress>` with the IP address retrieved in step 2.

### Naming homogenization
To homogenize the file names of laps and logs files in directories (as per laps.txt and adb_log_*.log):
1. For 1 directory:
   ```
   ./scripts/homogenize_fnames.sh path/to/dir [--skip_asking]
   ```
2. For multiple directories:
   ```
   ./scripts/multi_homogenize_fnames.sh "$dir" [--skip_asking]
   ```

## Video Analysis
- To extract the frames that might possibly be the timestamp boundaries of hmd through boundary:
    ```
    python video_analysis/extract_hmd_through_boundary_frames.py /path/to/experiment_dir --time_margin 0.5
    ```
- By using the option `--picker` a browser window opens with a picker of those images and using the arrows and keys 1, 2 you can set the fadein fadeout frames (in a separate txt file which is autogenerated in the same directory).
    ```
    python video_analysis/extract_hmd_through_boundary_frames.py /path/to/experiment_dir --picker
    ```
  This script actually calls functions from helpers and hmd_through_boundary.py, so you can also use those directly if only one of them is needed.
  Additionally, it calls:
    - video_analysis/video_rec_to_frames.py to extract the frames from the video, so you can also use that directly if you only need to extract frames.
    - video_analysis/visual_frame_picker.py to visualize the frames and pick the fadein and fadeout frames, so you can also use that directly if you only need to visualize the frames and pick the fadein and fadeout frames.
- To automatically detect the first/last frame boundary from extracted frames using SSIM-based scene-change detection (an alternative to the manual picker):
    ```
    python video_analysis/find_hmd_through_boundary_first_last_frames.py /path/to/frames_dir --window 7 --ssim_threshold 0.95 --output /path/to/output.txt
    ```

