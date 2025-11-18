# platform-mediated-avoidance-photometry
Alignment of TDT fiber photometry recordings with DeepLabCut and StateScript behavior tracking during platform-mediated avoidance procedure for mice.
Example data output, graphs, and detailed methods can be found at https://doi.org/10.1016/j.biopsych.2024.10.021

# Fiber Photometry + DeepLabCut + Behavioral State Alignment (MATLAB-based pipeline)

This repository contains a reproducible demonstration of how to integrate and analyze multimodal neuroscience data streams using MATLAB.  
It includes example code for:

- Loading and preprocessing fiber photometry data collected on TDT photometry system (https://www.tdt.com/system/fiber-photometry-system/)
- Integrating pose estimation output from DeepLabCut: Transformed from video input to csv output using Jupyter notebook and DeepLabCut trained networks
- Incorporating behavioral state information collected using StateScript from SpikeGadgets (https://spikegadgets.com/products/statescript/) 
- Aligning asynchronous data streams onto a unified timeline  
- Producing analysis-ready signals and visualizations  

---

## Project Structure
Project Structure

code/

get_fNames_AA.m – Choose cohort to analyze

TDT2MAT.m – Convert raw TDT data to MATLAB structure

Phot2PhotoSig.m – Clean and analyze photometry signal

batch_platformTimev3.m – Align timestamps across data streams

load_AA_data.m – Load photometry, DLC, and behavioral data

batch_TonexPhot.m – Analyze and generate figures for tone events

batch_ShockxPhot.m – Analyze and generate figures for shock events

batch_RewardxPhot.m – Analyze and generate figures for reward events

data_example/

fp_example.csv – Example photometry signal

dlc_example.csv – Example DeepLabCut pose output

behavior_states.csv – Example behavioral state timestamps

figures/

photometry_trace.png

dlc_aligned.png

behavior_overlay.png

.gitignore – Files Git should ignore

LICENSE – MIT License

README.md – Project overview and instructions

