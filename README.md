# MATLAB-EEG-waveForms

MATLAB helpers for plotting EEG/ERP conditional waveforms, difference
waveforms, confidence intervals, Bayesian bootstrap intervals, and group
peak-detection summaries.

The expected group data shape is:

```text
channels x time x conditions x subjects
```

The repository includes sample REWP grand ERP data:

```text
sampleGrandERP.mat
```

with variable:

```text
sampleGrandERP
```

The same file also contains EEGLAB-style channel locations in:

```text
chanlocs
```

For your own project, update `dataFile` and `chanlocsFile` in the examples or
pass your paths directly into the main functions.

## Path Setup

Add the repository folder to your MATLAB path:

```matlab
addpath('/path/to/MATLAB-EEG-waveForms');
```

## Subject Waveforms

Use `doWaveForms` for a subject-level 2 x 1 waveform figure. The top panel
shows both condition waveforms. The bottom panel shows the difference
waveform, where `ConditionPair(2)` is subtracted from `ConditionPair(1)`.

```matlab
outputs = doWaveForms('sampleGrandERP.mat', ...
    'DataVariable', 'sampleGrandERP', ...
    'ChanlocsFile', 'sampleGrandERP.mat', ...
    'SubjectIdx', 1, ...
    'ConditionPair', [1 2], ...
    'ConditionLabels', {'Win', 'Loss'}, ...
    'Channels', {'FCz'}, ...
    'StartTime', -200, ...
    'SamplingRate', 500, ...
    'OutputPrefix', 'rewp_sub01_cond01minus02_FCz');
```

## Group Waveforms

Use `doGroupWaveForms` for a group-level 3 x 1 waveform figure. The top panel
shows group mean condition waveforms. The second panel shows the group mean
difference waveform with a 95 percent confidence band. The third panel shows
the difference waveform with a Bayesian bootstrap confidence band.

```matlab
outputs = doGroupWaveForms('sampleGrandERP.mat', ...
    'DataVariable', 'sampleGrandERP', ...
    'ChanlocsFile', 'sampleGrandERP.mat', ...
    'ConditionPair', [1 2], ...
    'ConditionLabels', {'Win', 'Loss'}, ...
    'Channels', {'FCz'}, ...
    'StartTime', -200, ...
    'SamplingRate', 500, ...
    'OutputPrefix', 'rewp_group_cond01minus02_FCz');
```

## Peak Detection

Group runs also create a peak-detection figure by default. If `PeakTime` is
empty, the peak is selected from the group difference waveform using
`PeakPolarity`, which defaults to `positive`.

The peak summary includes:

- mean amplitude in `PeakTime +/- MeanWindowMs`, default `20 ms`
- max or min amplitude in `PeakTime +/- PeakWindowMs`, default `50 ms`
- latency of the max or min search

Example:

```matlab
outputs = doGroupWaveForms('sampleGrandERP.mat', ...
    'DataVariable', 'sampleGrandERP', ...
    'ChanlocsFile', 'sampleGrandERP.mat', ...
    'PeakPolarity', 'negative', ...
    'PeakTime', 300, ...
    'MeanWindowMs', 25, ...
    'PeakWindowMs', 60);
```

## Defaults

The default `ConditionPair` is `[1 2]`, so condition 2 is subtracted from
condition 1.

Timing defaults:

- `StartTime = -200` ms
- `SamplingRate = 500` Hz
- `PadToEvenTime = true`
- `EvenTimeStep = 100`

Plot defaults:

- y-axis label is `Voltage (uV)`
- positive voltage is plotted upward
- dashed zero-uV reference line is shown
- y-axis limits are shared across panels
- y-axis labels use 2-uV spacing
- difference waveforms are plotted in green

`Channels` defaults to `FCz` and can be a label, a cell array of labels, or
numeric indices:

```matlab
'Channels', {'FCz', 'Cz'}
'Channels', 34
'Channels', [34 11]
```

When multiple channels are selected, the waveform is the average across those
channels.

## Outputs

`doWaveForms` saves:

- `*_waveform.png`
- `*_waveform.csv`
- `*_waveform.mat`

`doGroupWaveForms` saves:

- `*_group_waveform.png`
- `*_group_waveform.csv`
- `*_group_waveform.mat`
- `*_peak_detection.png`
- `*_peak_detection.csv`

## Examples

From MATLAB:

```matlab
cd('/path/to/MATLAB-EEG-waveForms')
exampleSubjectWaveform
exampleGroupWaveform
```
