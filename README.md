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

## 🔧 Project Structure
photometry-video-behavior-alignment/
├── code/
│   ├── get_fNames_AA.m
│   ├── TDT2MAT.m
│   ├── Phot2PhotoSig.m
│   ├── batch_platformTimev3.m
│   ├── load_AA_data.m
│   ├── batch_TonexPhot.m
│   ├── batch_ShockxPhot.m
│   └── batch_RewardxPhot.m
├── data_example/
│   ├── fp_example.csv
│   ├── dlc_example.csv
│   └── behavior_states.csv
├── figures/
│   ├── photometry_trace.png
│   ├── dlc_aligned.png
│   └── behavior_overlay.png
├── .gitignore
├── LICENSE
└── README.md

