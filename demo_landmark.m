%% This demo demonstrates mapping using provided data with landmarks and mesh matlab files given.
clear all; clc; close all;

Setup.compile_dependencies();

% data full path
data_path = './data/centaur_0_to_centaur_1/';
%% Map parameters
alpha = 0.5;
gamma = 25;
beta = 5;
tet_uninv_nring = 1;
energy = @ARAP_energy;
lock_bd = false;
%% Load inputs
% load the mesh
Mesh = load([data_path,'meshes.mat']);
Mesh = Mesh.Mesh;
% load the landmarks
landmarks = load([data_path,'landmarks.mat']);
landmarks = landmarks.landmarks;
%% Map!
[X_12, X_21, P_12, P_21, E] = symmetric_volume_map(Mesh, alpha, gamma, beta, landmarks, energy, lock_bd, tet_uninv_nring);


timestamp = replace(string(datetime('now')), [" ", "-", ":"], "_");
workspace_name = sprintf("%s_%s", mfilename(), t);
save(workspace_name);
