function compile_dependencies()
    %COMPILE_DEPENDENCIES Summary of this function goes here
    %   NOTE: Requires the system to have both cmake and git installed
    
    cwd = pwd();
    libs_dir = fullfile(cwd,'libs');
    install_eigen(libs_dir);
    vcpkg_exe = install_vcpkg(libs_dir);
    install_lapack(libs_dir, vcpkg_exe);
    install_blas(libs_dir, vcpkg_exe);
    libigl_cmake_dir = install_libigl(libs_dir, vcpkg_exe);
    return
    install_gptoolbox(libs_dir, vcpkg_exe, libigl_cmake_dir);
    cd (cwd);
    disp("Depenency set up complete!")
end


function install_eigen(libs_dir)
    %INSTALL_EIGEN git clone v3.4 of Eigen and use it to compile SVD
    cwd = pwd();
    cd (libs_dir);
    eigen_dir = fullfile(libs_dir, 'eigen');
    if not(isfolder(eigen_dir))
        disp("Installing SVD Dependency: Eigen");
        !git clone https://gitlab.com/libeigen/eigen.git --branch 3.4
    else
        disp("SVD Dependency Already Installed: Eigen")
    end

    svd_path = fullfile(cwd, 'SVD');
    compile_svd(svd_path, eigen_dir);

    cd (cwd);
end


function compile_svd(svd_path, eigen_dir)
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
        fprintf(1,['Compiling ''%s''...'  newline], cpp_file);

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


function vcpkg_exe = install_vcpkg(libs_dir)
    %INSTALL_VCPKG Summary of this function goes here
    cwd = pwd();
    cd (libs_dir);
    if not(isfolder('vcpkg'))
        disp("Installing GPTOOLBOX Dependency: VCPKG");
        !git clone https://github.com/microsoft/vcpkg.git
    end

    cd vcpkg;
    vcpkg_exe = fullfile(pwd(), 'vcpkg.exe');
    if not(isfile(vcpkg_exe))
        !.\bootstrap-vcpkg.bat
    else
        disp("GPTOOLBOX Dependency Already Installed: VCPKG")
    end
    cd (cwd)
end


function install_lapack(libs_dir, vcpkg_exe)
    cwd = pwd();
    cd (libs_dir);
    disp("Installing GPTOOLBOX Dependency: lapack");
    lapack_cmd = sprintf("%s install lapack", vcpkg_exe);
    system(lapack_cmd, "-echo");
    cd (cwd);
end


function install_blas(libs_dir, vcpkg_exe)
    cwd = pwd();
    cd (libs_dir);
    disp("Installing GPTOOLBOX Dependency: blas");
    install_cmd = sprintf("%s install openblas", vcpkg_exe);
    system(install_cmd, "-echo");
    cd (cwd);
end


function libigl_cmake_dir = install_libigl(libs_dir, vcpkg_exe)
    cwd = pwd();
    cd (libs_dir);
    disp("Installing GPTOOLBOX Dependency: libigl");
    install_cmd = sprintf("%s install libigl", vcpkg_exe);
    system(install_cmd, "-echo");

    [vcpkg_dir, ~, ~] = fileparts(vcpkg_exe);
    config_pattern = fullfile(vcpkg_dir, 'installed', '**', 'libigl-config.cmake');
    dir_search = dir(config_pattern);
    libigl_cmake_dir = dir_search.folder;
    cd (cwd);
end


function eigen_cmake_dir = get_eigen_cmake_dir(vcpkg_root)
    config_pattern = fullfile(vcpkg_root, 'installed', '**', 'Eigen3Config.cmake');
    dir_search = dir(config_pattern);
    eigen_cmake_dir = dir_search.folder;
end


function install_gptoolbox(libs_dir, vcpkg_exe, libigl_cmake_dir)
    %INSTALL_GPTOOLBOX Summary of this function goes here
    % Instructions from here:
    % https://github.com/alecjacobson/gptoolbox/blob/master/mex/README.md
    cwd = pwd();
    cd (libs_dir);
    gptoolbox_dir = fullfile(libs_dir, 'gptoolbox');

    if not(isfolder(gptoolbox_dir))
        disp("Installing Dependency: GPTOOLBOX")
        !git clone https://github.com/alecjacobson/gptoolbox.git
    else
        disp("Dependency Already Installed: GPTOOLBOX")
    end

    % Edit GPTOOLBOX CMakeLists.txt to use libigl from vcpkg
    edit_cmake_lists(gptoolbox_dir);
     
    % Edit GPTOOLBOX FindMATLAB.cmake to include this version of Matlab
    cmake_dir = fullfile(gptoolbox_dir, 'mex', 'cmake');
    edit_matlab_version_map(cmake_dir);

    build_dir = fullfile(gptoolbox_dir, 'mex', 'build');
    if not(isfolder(build_dir))
        mkdir(build_dir);
    end
    cd (build_dir);
   
    disp("Compiling GPTOOLBOX")
    [vcpkg_root, ~, ~] = fileparts(vcpkg_exe);
    z_vcpkg_exe = sprintf("-D Z_VCPKG_EXECUTABLE=%s", vcpkg_exe);
    z_vcpkg_root = sprintf("-D Z_VCPKG_ROOT_DIR=%s", vcpkg_root);
    z_libigl_dir = sprintf("-D LIBIGL_DIR=%s", libigl_cmake_dir);
    z_eigen_dir = sprintf("-D Eigen3_DIR=%s", get_eigen_cmake_dir(vcpkg_root));
    cmake_cmd = sprintf( ...
        "cmake ..  %s %s %s %s", ...
        z_vcpkg_exe, ...
        z_vcpkg_root, ...
        z_libigl_dir, ...
        z_eigen_dir ...
    );
    system(cmake_cmd,"-echo");
    !cmake --build . --config Release

    compile_toolbox_fast_marching(gptoolbox_dir);
    
    cd (cwd);
end


function compile_toolbox_fast_marching(gptoolbox_dir)
    disp("Compiling toolbox_fast_marching")
    cwd = pwd();
    fast_march_dir = fullfile(gptoolbox_dir, 'external', 'toolbox_fast_marching');
    cd (fast_march_dir);
    run("compile_mex.m");
    cd(cwd);
end


function edit_matlab_version_map(cmake_dir)
    % Edit GPTOOLBOX FindMATLAB.cmake to include this version of Matlab
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
end


function [ver_num, ver_name] = get_matlab_version_info()
    version_info = split(version, ' ');
    ver_name = erase(erase(version_info{2}, '('), ')');
    version_nums = split(version_info{1}, '.');
    ver_num = [version_nums{1} '.' version_nums{2}];
end


function edit_cmake_lists(gptoolbox_dir)
    % Edit GPTOOLBOX CMakeLists.txt to use the libigl installed by vcpkg
    file_name = 'CMakeLists.txt';
    cmake_lists = fullfile(gptoolbox_dir, 'mex', file_name);
    
    if not(isfile(cmake_lists))
        fprintf("Error: Could not find %s\n", file_name);
        return
    end

    cd (gptoolbox_dir);

    % Read text from file as array of stings
    fid = fopen(cmake_lists,"r");
    text_cell_array = textscan(fid, '%s','delimiter','\n', 'whitespace', '');
    f_text = text_cell_array{1,1};
    
    % find_package(libigl CONFIG REQUIRED)
    % target_link_libraries(main PRIVATE igl::igl_core igl_copyleft::igl_copyleft_core)

    target_line = 'include(libigl)';
    new_lines = [ ...
        sprintf("%s%s", 'include(FetchContent)  # prevents errors from removing include(libigl)', newline), ...
        sprintf("%s%s", 'find_package(LIBIGL CONFIG REQUIRED)  # include(libigl)', newline), ...
        'target_link_libraries(main PRIVATE igl::igl_core igl_copyleft::igl_copyleft_core)', ...
    ];
    inserted_line = sprintf("%s%s%s", new_lines(1), new_lines(2), new_lines(2));

    if contains(f_text, inserted_line)
        return
    end
    new_text = replace(f_text, target_line, inserted_line);

    % Write new text to file
    fid = fopen(cmake_lists, 'wt');
    fprintf(fid, '%s\n', new_text{:});
    fclose(fid);

    disp("CMakeLists.txt editing complete");
end