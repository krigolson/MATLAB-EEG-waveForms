% MATLAB-EEG-waveForms
%
% Waveform and peak-detection plotting tools for EEG/ERP data.
%
% Main functions
%   doWaveForms       - Subject-level conditional and difference waveforms.
%   doGroupWaveForms  - Group-level waveforms, confidence bands, and peak detection.
%   wf_write_peak_stats_csv - Write group statistics for peak measures.
%
% Example scripts
%   exampleSubjectWaveform - Example subject-level waveform call.
%   exampleGroupWaveform   - Example group-level waveform and peak-detection call.
%
% Expected data shape
%   channels x time x conditions x subjects
%
% Channel locations
%   EEGLAB-style chanlocs saved in a MAT file containing variable chanlocs.
