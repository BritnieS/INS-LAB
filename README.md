# HD-sEMG Hand Gesture Recognition

This project evaluates and compares two different strategies for classifying hand gestures using **High-Density Surface Electromyography (HD-sEMG)**. The research focuses on comparing traditional feature-engineered Machine Learning against end-to-end Deep Learning.

## 📋 Project Overview
Hand gesture recognition via sEMG is a vital component for controlling prosthetic limbs and rehabilitative devices. This project utilizes **High-Density** arrays to capture detailed spatial maps of muscle activity, overcoming the low strength and noise susceptibility of traditional sparse electrode configurations.

## ✨ Key Features
* **High-Density Data**: Uses two 64-channel grids (128 channels total) in a "bracelet" formation around the mid-forearm.
* **Gesture Vocabulary**: Classifies six states: **Stone, Paper, Scissors, Pointing, Rock, and Rest**.
* **Adaptive Preprocessing**:
    * **Filtering**: 50 Hz notch filter and 20–500 Hz bandpass filter to isolate physiological signals.
    * **Dynamic Thresholding**: Subject-specific segmentation using the formula:  
        $$Threshold = \mu_{rest} + 3\sigma_{rest}$$ 
    * **Advanced Cleaning**: Employs **Independent Component Analysis (ICA)** specifically for Subject P2 to isolate and remove artifacts.

## 🏗️ Classification Pipelines

### 1. Feature-Engineered ML (Ensemble)
* **Architecture**: A **Soft Voting Ensemble** combining Random Forest, SVM (RBF kernel), and K-Nearest Neighbors.
* **Feature Extraction**: Extracts time-domain features—**MAV, RMS, and ZCR**—from spatial muscle zones.
* **Primary Strength**: High computational efficiency and decision transparency.

### 2. End-to-End Deep Learning (CNN)
* **Architecture**: A 3-layer Convolutional Neural Network (16, 32, and 64 filters) followed by ReLU activation and max pooling.
* **Input**: Raw spatial-temporal tensors, allowing the model to perform automatic feature discovery.
* **Primary Strength**: Better extraction of core spatial muscle recruitment patterns, leading to superior generalization.

## 📊 Performance Comparison

| Metric | ML Ensemble | CNN Model |
| :--- | :--- | :--- |
| **Intra-Subject Accuracy** | 80.50% | 91.00% |
| **Cross-Subject (LOSO) Accuracy** | 29.51% | 51.86% |

**Leave-One-Subject-Out (LOSO)** validation reveals that while ML models are sensitive to "spatial shifts" caused by anatomical differences, the CNN nearly doubles the accuracy for new, unseen users.

## 🚀 Setup & Deployment
1.  **Data**: Organize `.mat` files into subject-specific folders (e.g., `/P1/`, `/P2/`).
2.  **Containerization**: A Docker image is provided for real-time visualization:
    ```bash
    docker run -p 5000:5000 madaraa/emg-app:v1
    ```

## ✍️ Authors
* **Britnie Anthonisamy** 
* **Mahmoud Afifi** 

**Affiliation**: N-Squared Lab, Friedrich-Alexander-Universität Erlangen-Nürnberg.  
**Supervision**: Marius Osswald.
