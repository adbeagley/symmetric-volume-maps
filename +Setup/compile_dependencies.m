function compile_dependencies()
    %COMPILE_DEPENDENCIES Summary of this function goes here
    %   NOTE: Requires the system to have both cmake and git installed
    
    cwd = pwd();
    libs_dir = fullfile(cwd,'libs');
    install_eigen(libs_dir);
    vcpkg_exe = install_vcpkg(libs_dir);
    install_lapack_blas(libs_dir, vcpkg_exe);
    install_gptoolbox(libs_dir, vcpkg_exe);
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
    

function install_lapack_blas(libs_dir, vcpkg_exe)
    cwd = pwd();
    cd (libs_dir);
    lapack_cmd = sprintf("%s install lapack", vcpkg_exe);
    system(lapack_cmd, "-echo");
    cd (cwd);
end


function install_gptoolbox(libs_dir, vcpkg_exe)
    %INSTALL_GPTOOLBOX Summary of this function goes here
    cwd = pwd();
    cd (libs_dir);
    
    if not(isfolder('gptoolbox'))
        disp("Installing Dependency: GPTOOLBOX")
        !git clone https://github.com/alecjacobson/gptoolbox.git
    else
        disp("Dependency Already Installed: GPTOOLBOX")
    end
    
    build_dir = fullfile(libs_dir, 'gptoolbox', 'mex', 'build');
    if not(isfolder(build_dir))
        mkdir(build_dir);
    end
    cd (build_dir);
    
    disp("Compiling GPTOOLBOX")
    cmake_cmd = sprintf("cmake .. -D Z_VCPKG_EXECUTABLE=%s", vcpkg_exe);
    system(cmake_cmd,"-echo");
    
    cd (cwd);
end
