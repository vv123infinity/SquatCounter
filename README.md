# A simple PoseNet-based squat counter iOS app
## Basic Environment

*macOS Ventura 13.1, Xcode 14.2, Swift, Storyboard*🤖

## Description

This is an iOS application based on the human pose estimation model PoseNet, which is used to calculate the number of user squats. PoseNet is from [Apple's website](https://developer.apple.com/machine-learning/models/).

## About PoseNet and Squats counting rules

PoseNet is a deep learning model that allows you to detect the pose of a person based on where their joints are. PoseNet will detect the pose of a video or image and output coordinates of keypoints with relative confidence scores and a total confidence score.

For the side pose, we try to compute the angle of the main part of the human pose to test whether a user has done a deep squat. And we use the study result in [1] and the obvious of squat in daily to set a counting rule. Figure 1 demonstrates the side pose counting method and Table 1 shows a range of angles for reference.

<img src="./img/side.png" style="zoom: 33%;" >
<center>Figure 1: Side standing squat judgment method.</center>

| Angle type | Relative Points | Range    |
| ---------- | --------------- | -------- |
| Trunk      | E—B—A           | 38.8±5.2 |
| Hip        | A—B—C           | 57.0±9.7 |
| Knee       | B—C—D           | 62.6±6.3 |

<center>Table 1: A range of angles for reference.</center>


