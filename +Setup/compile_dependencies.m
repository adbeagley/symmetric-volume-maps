function compile_dependencies()
    %COMPILE_DEPENDENCIES Summary of this function goes here
    %   NOTE: Requires the system to have both cmake and git installed

    cwd = pwd();
    libs_dir = fullfile(cwd,'libs');
    compile_svd(libs_dir);
    install_gptoolbox(libs_dir);
    cd (cwd);
    disp("Depenency set up complete!")
end


function compile_svd(libs_dir)
    % Fetch eigen from Github and compile the file in SVD
    cwd = pwd();
    svd_path = fullfile(cwd, 'SVD');
    eigen_dir = fetch_eigen(libs_dir);

    % Compile SVD functions using mex and eigen header files
    mex -setup

    target_files = ["batchSVD3x3Eigen"];

    cxx_flags = 'CXXFLAGS=$CXXFLAGS -std=c++11 -fopenmp';
    cxx_opt_flags = 'CXXOPTIMFLAGS=$CXXOPTIMFLAGS -Ofast -DNDEBUG';
    ld_opt_flags = 'LDOPTIMFLAGS=$LDOPTIMFLAGS -fopenmp -O2 -lgomp';
    includeoption = ['-I' eigen_dir];

    for i=1:numel(target_files)
        cpp_file = [target_files{i} '.cpp'];
        cpp_path = fullfile(svd_path, cpp_file);
        fprintf(1, ['Compiling ''%s''...'  newline], cpp_file);

        err = mex( ...
            cxx_flags,...
            cxx_opt_flags, ...
            ld_opt_flags, ...
            includeoption,...
            '-outdir', ...
            svd_path, ...
            cpp_path ...
            );
        if err ~= 0
            error('compile failed!');
        end
    end
end

function eigen_dir = fetch_eigen(libs_dir)
    % git clone v3.4 of Eigen so it can be used to compile SVD
    cwd = pwd();
    cd (libs_dir);

    eigen_dir = fullfile(libs_dir, 'eigen');
    if not(isfolder(eigen_dir))
        disp("Installing SVD Dependency: Eigen");
        !git clone https://gitlab.com/libeigen/eigen.git --branch 3.4
    else
        disp("SVD Dependency Already Installed: Eigen")
    end

    cd (cwd);
end



function install_gptoolbox(libs_dir)
    %INSTALL_GPTOOLBOX Summary of this function goes here
    % Instructions from here:
    % https://github.com/alecjacobson/gptoolbox/blob/master/mex/README.md
    cwd = pwd();
    cd (libs_dir);
    gptoolbox_dir = fetch_gptoolbox(libs_dir);
    edit_matlab_version_map(gptoolbox_dir);
    compile_gptoolbox_mex(gptoolbox_dir);
    compile_toolbox_fast_marching(gptoolbox_dir)
    cd (cwd);
end

function gptoolbox_dir = fetch_gptoolbox(libs_dir)
    % Fetch gptoolbox from github
    cwd = pwd();
    cd (libs_dir);
    gptoolbox_dir = fullfile(libs_dir, 'gptoolbox');

    if not(isfolder(gptoolbox_dir))
        disp("Installing Dependency: GPTOOLBOX")
        !git clone https://github.com/alecjacobson/gptoolbox.git
    else
        disp("Dependency Already Installed: GPTOOLBOX")
    end
    cd (cwd);
end


function edit_matlab_version_map(gptoolbox_dir)
    % Edit GPTOOLBOX FindMATLAB.cmake to include this version of Matlab
    cwd = pwd();

    cmake_dir = fullfile(gptoolbox_dir, 'mex', 'cmake');
    file_name = 'FindMATLAB.cmake';
    find_matlab_cmake = fullfile(cmake_dir, file_name);

    if not(isfile(find_matlab_cmake))
        fprintf("Error: Could not find %s\n", file_name);
        return
    end

    cd (cmake_dir);

    % Create version mapping
    [ver_num, ver_name] = get_matlab_version_info();
    matlab_ver_map_str = sprintf("%s%s=%s%s", '"', ver_name, ver_num, '"');

    % Read text from file as array of stings
    fid = fopen(find_matlab_cmake,"r");
    text_cell_array = textscan(fid, '%s','delimiter','\n', 'whitespace', '');
    f_text = text_cell_array{1,1};
    fclose(fid);

    % Check if mapping already exists and edit if not
    mapping_matches = contains(f_text, matlab_ver_map_str);
    if sum(mapping_matches) ~= 0
        disp("Mapping for current version of Matlab already exists");
        return
    end

    disp("Creating mapping for current version of Matlab");
    TF = contains(f_text, 'set(MATLAB_VERSIONS_MAPPING');
    if sum(TF) == 0
        disp("Error: Failed to find MATLAB_VERSIONS_MAPPING")
        return
    end

    % Fetch example line to manage whitespace correctly
    mapping_start_line = find(TF == 1);
    example_line = f_text{mapping_start_line+1, 1};
    new_line = regexprep(example_line, '".+"', matlab_ver_map_str);

    % insert new_line via concatenation
    new_text = [f_text{1:mapping_start_line} {new_line} f_text{mapping_start_line+2:end}];

    % Write new text to file
    fid = fopen(find_matlab_cmake, 'wt');
    fprintf(fid, '%s\n', new_text{:});
    fclose(fid);

    disp("Matlab version mapping editing complete");

    cd (cwd);
end


function [ver_num, ver_name] = get_matlab_version_info()
    % Get version number and name for current version of matlab
    version_info = split(version, ' ');
    ver_name = erase(erase(version_info{2}, '('), ')');
    version_nums = split(version_info{1}, '.');
    ver_num = [version_nums{1} '.' version_nums{2}];
end


function compile_gptoolbox_mex(gptoolbox_dir)
    % Compile the functions in the mex folder of GPTOOLBOX
    cwd = pwd();

    build_dir = fullfile(gptoolbox_dir, 'mex', 'build');
    if not(isfolder(build_dir))
        mkdir(build_dir);
    end
    cd (build_dir);

    disp("Compiling GPTOOLBOX")
    system("cmake ..","-echo");
    !cmake --build . --config Release

    cd (cwd);
end


function compile_toolbox_fast_marching(gptoolbox_dir)
    % Compile toolbox_fast_marching within GPTOOLBOX
    disp("Compiling toolbox_fast_marching")
    cwd = pwd();
    fast_march_dir = fullfile(gptoolbox_dir, 'external', 'toolbox_fast_marching');
    cd (fast_march_dir);
    run("compile_mex.m");
    cd(cwd);
end
