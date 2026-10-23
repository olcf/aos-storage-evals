# Technology Evaluations for OLCF-6 AI-Optimized Storage (AOS)

## Description

This repository is intended to capture all the artifacts of the AOS technology evaluations.
The goal is to make sure the evaluations are conducted using consistent methods, and to support reproducibility requirements for an eventual paper submission.

Artifacts include things such as:

- Descriptions of the evaluation platforms, including their hardware and software
- Source code for applications and benchmarks
- Utility scripts for installing software or configuring platforms
- Experiment and test descriptions, scripts, and raw and processed results

An **experiment** is assumed to be a related set of tests, where each **test** represents execution of an app/benchmark with a specific test configuration.

## QUICKSTART: Running a Test

1. Get an interactive Slurm job

   ```bash
   salloc -N<#nodes>
   ```

2. Set necessary environment:

   NOTE: for details of each env var, see 'AOS Environment Tunables' section below

   - `AOS_PROJECT_DIR`
   - `AOS_REPO_ROOT`
   - `AOS_PLATFORM_CLIENT`
   - `AOS_PLATFORM_SERVER`
   - `AOS_EXPERIMENT_NAME`
   - `AOS_TEST_NAME`
   - `AOS_SOURCE` (only necessary for dataset `copy` tests)
   - `AOS_TARGET`

3. Execute the test's run script:

   The name of the run script varies per test, but the following generic command works for
   many of the experiment tests.

   ```bash
   $AOS_REPO_ROOT/experiments/$AOS_EXPERIMENT_NAME/$AOS_TEST_NAME/scripts/run/run*.slurm
   ```

4. Examine the test run results in the per-run output directory:

   The per-run output directory (aka rundir) is automatically created by the testing 
   infrastructure and named as follows - `$AOS_JOB_WORKDIR/run.<date>_<time>`.
   The rundir holds both the test configuration files (in `<rundir>/config/`) and
   any logs (in `<rundir>/logs/`).

## Repository Organization

*NOTE*: This is subject to change

```bash
# Area for capturing experiment descriptions, configurations, and results.
experiments/
           /<exp_name>/
                      /exp.cfg  # optional base experiment config
                      /description/
                                  /summary.txt     # summary of the experiment
                                  /<test_name>.txt # description of test
                      /<test_name>/
                                  /test.cfg  # optional base test config
                                  /scripts/
                                          /analysis/ # scripts for analysis of raw test results
                                          /config/   # scripts for configuring the test environment
                                                 /<platform_name>.platform.cfg  # optional test-specific platform config
                                                 /<config_name>.<software_name>.cfg  # configuration(s) for software used by test
                                          /run/ # scripts for running the test
                                  /results/
                                          /<server_platform>/
                                                            /<client_platform>/
                                                                              /raw/
                                                                              /processed/
                      /scripts/
                              /analysis/ # scripts for analysis of processed test results
                              /config/   # scripts for configuring experiment environments
                                     /client/<platform_name>/
                                     /server/<platform_name>/
                              /run/ # scripts for running experiments (i.e., many tests)
                      /results/
                              /<server_platform>/

# Area for capturing platform descriptions
platforms/
         /client/
                /<platform_name>/
                                /platform.cfg
                                /hardware.txt
                                /software.txt
         /server/
                /<platform_name>/
                                /platform.cfg
                                /hardware.txt
                                /software.txt

# Common scripts used across platforms and experiments
scripts/
       /configuration/
       /experiment/
       /installation/

# Source code (preferably unmodified tarballs for released versions)
source/
      /benchmarks/
                 /<benchmark_name>/<version>/
                                            /software.cfg
      /applications/
                   /<app_name>/<version>/
                                        /software.cfg

```

## AOS Environment Tunables

*NOTE*: These are subject to change

Here is the current list of AOS Environment Tunables that can be used in scripts or configuration files (*.cfg).

- `AOS_PROJECT_DIR` : `[path]` path to AOS project directory containing datasets and platform software installations

- `AOS_SOURCE` : `[path]` source dataset - file/directory path to use as source for data movement operations (e.g., copy)
- `AOS_TARGET` : `[path]` target dataset - file/directory path or URI (e.g., '`daos://<pool>/<container>/path/to/target`' for a DAOS POSIX container target) to use as I/O target or destination for data movement operations
- `AOS_TARGET_CREATE` : `[0|1]` whether to create the I/O target or use an existing one (default: 0, use existing)

- `AOS_EXPERIMENT_NAME` : `[string]` name of the current experiment (no spaces allowed; should match directory name)
- `AOS_EXPERIMENT_RUN_STAMP` : `[string]` timestamp of current experiment run for use in creating unique per-experiment files
- `AOS_EXPERIMENT_RUN_DIR` : `[path]` unique per-experiment run directory (automatically set using `$AOS_JOB_WORKDIR`, `$AOS_EXPERIMENT_NAME`, and `$AOS_EXPERIMENT_RUN_STAMP`)
- `AOS_EXPERIMENT_ABORT_ON_TEST_ERROR` : `[0|1]` whether to immediately exit experiment script when an error is encountered during a test run (default: 0)

- `AOS_TEST_NAME` : `[string]` name of the current test (no spaces allowed; should match directory name)
- `AOS_TEST_RUN_STAMP` : `[string]` timestamp of current test run for use in creating unique per-run files
- `AOS_TEST_RUN_DIR` : `[path]` unique per-test run directory (automatically set using `$AOS_EXPERIMENT_RUN_DIR`, `$AOS_TEST_NAME`, and `$AOS_TEST_RUN_STAMP`)
- `AOS_TEST_RUN_INIT_COMMANDS` : `array[string]` array of commands to run at test initialization (set by test configuration)
- `AOS_TEST_RUN_FINI_COMMANDS` : `array[string]` array of commands to run at test finalization (set by test configuration)
- `AOS_TEST_CONFIG_LOG` : `[path]` path to file that should be used to capture all imported configuration settings

- `AOS_CLIENT_CONFIG` : `[string]` name of the client configuration file (should match file name in `$AOS_REPO_TEST_DIR/scripts/config/` subdir)
- `AOS_CLIENT_SOFTWARE` : `[string]` name of the software application, benchmark, or utility used for client I/O (should match directory name)
- `AOS_CLIENT_SOFTWARE_VERSION` : `[string]` version of the software application or benchmark used for client I/O (should match directory name)
- `AOS_CLIENT_COMMAND` : `[string]` full command-line (exe + args) to use to launch client
- `AOS_CLIENT_SVC_COMMAND` : `[string]` full command-line (exe + args) to use to launch client service
- `AOS_CLIENT_DEBUG` : `[0|1]` whether to run client application under the gdb debugger (default: 0)
- `AOS_CLIENT_PARALLEL` : `[0|1]` whether client software needs a parallel job environment (default: 0)
- `AOS_CLIENT_MPI` : `[string]` which MPI implementation should be used to run parallel client (default: none; supported values: `mpich`, `openmpi`)
- `AOS_CLIENT_NODES` : `[int]` when using parallel job, number of client nodes to use (default: $AOS_JOB_SIZE)
- `AOS_CLIENT_PROCS_PER_NODE` : `[int]` when using parallel job, number of client processes to launch per node (default: 1)
- `AOS_CLIENT_THREADS_PER_PROC` : `[int]` number of client threads to use per process (default: 1)

- `AOS_IO_FILE_COUNT` : `[int]` target file count for datasets with many files
- `AOS_IO_FILE_SIZE` : `[int]` target file size in bytes
- `AOS_IO_REQUEST_SIZE` : `[int]` number of bytes per client I/O request
- `AOS_IO_BLOCK_SIZE` : `[int]` number of contiguous bytes per client (should be multiple of request size)
- `AOS_IO_QUEUE_DEPTH` : `[int]` depth of client I/O request queue
- `AOS_IO_UNIQUE_DIR` : `[0|1]` whether to use a per-client process unique directory (default: 0)
- `AOS_IO_DIRECT` : `[0|1]` whether to use direct I/O (default: 0)

- `AOS_JOB_QUEUE` : `[string]` name of queue/partition to use for job submission
- `AOS_JOB_SIZE` : `[int]` number of nodes allocated to current job (default: 1)
- `AOS_JOB_WORKDIR` : `[path]` absolute path to job working directory (default: current working directory of job submission)
- `AOS_JOB_HOST_FILE` : `[path]` absolute path to generated file containing list of allocated job nodes with one host per line (automatically set for all jobs)
- `AOS_JOB_HOST_LIST` : `[string]` comma-separated list of allocated job nodes (automatically set for all jobs)

- `AOS_PLATFORM_CLIENT` : `[string]` name of the platform where I/O clients run (no spaces allowed; should match directory name)
- `AOS_PLATFORM_SERVER` : `[string]` name of the I/O server platform (no spaces allowed; should match directory name)

- `AOS_REPO_ROOT` : `[path]` absolute path to root of aos-storage-evals git repository
- `AOS_REPO_EXPERIMENT_DIR` : `[path]` absolute path to the repo directory for the current experiment (default: `$AOS_REPO_ROOT/experiments/$AOS_EXPERIMENT_NAME`)
- `AOS_REPO_TEST_DIR` : `[path]` absolute path to the repo directory for the current test (default: `$AOS_REPO_ROOT/experiments/$AOS_EXPERIMENT_NAME/$AOS_TEST_NAME`)

- `AOS_SCRIPT_DEBUG` : `[0|1]` whether to turn on debug statements within executed scripts
