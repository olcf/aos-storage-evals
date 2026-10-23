#include <mpi.h>

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/uio.h>

#include <getopt.h>
extern char *optarg;
extern int optopt;

const char* posix_tmpdir = P_tmpdir;

// getopt options
const char* program_options = "B:C:D:hrS:uwW:";

// global options and default values
int warmup_seconds = 10;   // -W <seconds>
int bench_seconds = 60;    // -B <seconds>
int reader = 0;            // -r
int writer = 0;            // -w
int unique_dir = 0;        // -u
int file_count = 100;      // -C <count>
int file_size = 32768;     // -S <bytes>
char* target_dir = NULL;   // -D <path>

size_t write_buffer_sz = 8 * 1048576; /* 8 MiB */
void* write_buffer = NULL;
void* read_buffer = NULL;

int create_and_write_file(int rank, char* filename)
{
    int err, fd;
    int ret = 0;
    int create_flags = O_CREAT | O_TRUNC | O_WRONLY;
    mode_t create_mode = 0600;
    
    errno = 0;
    fd = open(filename, create_flags, create_mode);
    err = errno;
    if (-1 == fd) {
        fprintf(stderr, "ERROR: [%d] creat() failed - %s\n",
                rank, strerror(err));
        ret = err;
    } else {
        int nwritten = 0;
        size_t towrite = file_size;
        int rand_offset = rand() % (int)write_buffer_sz;
        if (rand_offset > ((int)write_buffer_sz - file_size)) {
            rand_offset -= file_size;
        }
        do {
            void* buf = write_buffer + rand_offset + nwritten;
            errno = 0;
            ssize_t nwrite = write(fd, buf, towrite);
            if ((ssize_t)-1 == nwrite) {
                err = errno;
                fprintf(stderr, "ERROR: [%d] write() failed - %s\n",
                        rank, strerror(err));
                ret = err;
                break;
            } else {
                nwritten += (int)nwrite;
                towrite -= nwrite;
            }
        } while (nwritten < file_size);
        close(fd);
    }
    return ret;
}

int stat_and_read_file(int rank, char* filename)
{
    int err, fd, rc;
    int ret = 0;
    int read_flags = O_RDONLY;

    struct stat file_stats;
    errno = 0;
    rc = stat(filename, &file_stats);
    err = errno;
    if (-1 == rc) {
        fprintf(stderr, "ERROR: [%d] stat(%s) failed - %s\n",
                rank, filename, strerror(err));
        return err;
    }
    
    errno = 0;
    fd = open(filename, read_flags);
    err = errno;
    if (-1 == fd) {
        fprintf(stderr, "ERROR: [%d] creat() failed - %s\n",
                rank, strerror(err));
        ret = err;
    } else {
        int nread = 0;
        size_t file_sz = file_stats.st_size;
        size_t toread = file_sz;
        do {
            void* buf = read_buffer + nread;
            errno = 0;
            ssize_t nrd = read(fd, buf, toread);
            if ((ssize_t)-1 == nrd) {
                err = errno;
                fprintf(stderr, "ERROR: [%d] read() failed - %s\n",
                        rank, strerror(err));
                ret = err;
                break;
            } else {
                nread += (int)nrd;
                toread -= nrd;
            }
        } while (nread < file_sz);
        close(fd);
    }
    return ret;
}

int usage(char* arg0)
{
    fprintf(stderr, "USAGE: %s <options>\n", arg0);
    fprintf(stderr, "OPTIONS:\n");
    fprintf(stderr, "-r : act as file reader (default: off)\n");
    fprintf(stderr, "-w : act as file creator/writer (default: off)\n");
    fprintf(stderr, "-u : create/read files in unique directory per client process (default: off)\n");
    fprintf(stderr, "-D <dir> : target directory where files will be created/read (default: none)\n");
    fprintf(stderr, "-B <sec> : number of seconds to run benchmark phase (default: 10)\n");
    fprintf(stderr, "-W <sec> : number of seconds to run warmup phase (default: 60)\n");
    fprintf(stderr, "-C <count> : maximum number of files to create/read per client (default: 100)\n");
    fprintf(stderr, "-S <bytes> : file size in bytes (default: 32 KiB)\n");
    fflush(stderr);
    return 0;
}

int main(int argc, char** argv)
{
    int err, opt, rc;
    int rank, world_sz;

    char hostname[64];
    memset(hostname, 0, sizeof(hostname));
    gethostname(hostname, sizeof(hostname));
    hostname[63] = '\0';

    rc = MPI_Init(&argc, &argv);
    if (rc != MPI_SUCCESS) {
        fprintf(stderr, "ERROR: MPI_Init() failed with rc=%d\n", rc);
        return -1;
    }
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &world_sz);

    // process options
    while (-1 != (opt = getopt(argc, argv, program_options))) {
        switch(opt) {
            case 'B':
                bench_seconds = atoi(optarg);
                break;
            case 'C':
                file_count = atoi(optarg);
                break;
            case 'D':
                target_dir = strdup(optarg);
                break;
            case 'h':
                usage(argv[0]);
                return 0;
            case 'r':
                reader = 1;
                break;
            case 'S':
                file_size = atoi(optarg);
                break;
            case 'u':
                unique_dir = 1;
                break;
            case 'w':
                writer = 1;
                break;
            case 'W':
                warmup_seconds = atoi(optarg);
                break;
            default:
                fprintf(stderr, "USAGE ERROR: unknown option '%c'\n",
                        (char)optopt);
                usage(argv[0]);
                return -1;
        }
    }

    if (0 == (reader + writer)) {
        fprintf(stderr, "USAGE ERROR: -r or -w or both must be specified\n");
                return -1;
    }

    if (NULL == target_dir) {
        target_dir = strdup(posix_tmpdir);
    }
    if (unique_dir) {
        char my_dirname[256];
        snprintf(my_dirname, sizeof(my_dirname), "%s/rank-%d",
                 target_dir, rank);
        
        if (writer) {
            errno = 0;
            rc = mkdir(my_dirname, 0700);
            err = errno;
            if (-1 == rc) {
                fprintf(stderr, "ERROR: could not create directory %s - %s\n",
                        my_dirname, strerror(err));
                return -1;
            }
        }
        free(target_dir);
        target_dir = strdup(my_dirname);
    }

    if (writer) {
        // initialize write buffer with random data
        write_buffer = malloc(write_buffer_sz);
        if (NULL == write_buffer) {
            fprintf(stderr, "ERROR: could not allocate write buffer\n");
            return -1;
        } else {
            errno = 0;
            int rand_fd = open("/dev/urandom", O_RDONLY);
            if (-1 != rand_fd) {
                errno = 0;
                ssize_t nread = read(rand_fd, write_buffer, write_buffer_sz);
                if (nread != write_buffer_sz) {
                    fprintf(stderr, "WARNING: short random data\n");
                }
                close(rand_fd);
            }
        }
    }

    if (reader) {
        // initialize read buffer
        read_buffer = malloc(file_size);
        if (NULL == read_buffer) {
            fprintf(stderr, "ERROR: could not allocate read buffer\n");
            return -1;
        }
    }
    
    srand(rank);

    /*
    fprintf(stdout, "[%d of %d] Hello from %s\n",
            rank, world_sz, hostname);
    */	
    MPI_Barrier(MPI_COMM_WORLD);

    char filename[256];
    int curr_file_ndx = 0;
    int done = 0;
    int warming = 1;
    int files_processed = 0;
    time_t start_warm = time(NULL);
    time_t start_bench = 0;
    time_t stop_bench = 0;
    do {
        time_t now = time(NULL);
        
        if (warming) {
            if (warmup_seconds <= (int)(now - start_warm)) {
                warming = 0;
                files_processed = 0;
                start_bench = now;
            }
        } else if (bench_seconds <= (int)(now - start_bench)) {
            stop_bench = now;
            done = 1;
        }

        if (!done) {
            snprintf(filename, sizeof(filename), "%s/r%d.f%d",
                     target_dir, rank, curr_file_ndx);
            rc = 0;
            /*
            fprintf(stderr, "DEBUG: [%d] processing file %s\n",
                    rank, filename);
            fflush(NULL);
            */
            if (writer) {
                rc = create_and_write_file(rank, filename);
            }
            if (reader && (0 == rc)) {
                rc = stat_and_read_file(rank, filename);
            }

            if (0 == rc) {
                files_processed++;
                curr_file_ndx++;
                // if we're at max file count, wrap around
                if (curr_file_ndx == file_count)
                    curr_file_ndx = 0;        
            } else {
                done = 1;
            }
        }
    } while (!done);
    
    int bench_time = (int)(stop_bench - start_bench);
    double fps = (double) files_processed / (double) bench_time;
    
    MPI_Barrier(MPI_COMM_WORLD);

    double total_fps = 0.0;
    double min_fps = 0.0;
    double max_fps = 0.0;
    rc = MPI_Reduce(&fps, &total_fps, 1, MPI_DOUBLE, MPI_SUM,
                    0, MPI_COMM_WORLD);
    rc = MPI_Reduce(&fps, &min_fps, 1, MPI_DOUBLE, MPI_MIN,
                    0, MPI_COMM_WORLD);
    rc = MPI_Reduce(&fps, &max_fps, 1, MPI_DOUBLE, MPI_MAX,
                    0, MPI_COMM_WORLD);
    if (0 == rank) {
        fprintf(stdout,
                "RESULT: %.1lf files processed per second across %d clients"
                " (MIN=%.1lf, MAX=%.1lf, AVG=%.1lf)\n",
                total_fps, world_sz, min_fps, max_fps, (total_fps/world_sz));
    }

    /*
    fprintf(stdout, "[%d] %d files processed in %d seconds (%.1f fps)\n",
            rank, files_processed, bench_time, fps);
    */

    /* When run includes both write and read, remove created files/directory */
    if (writer && reader) {
        for (int ndx=0; ndx < file_count; ndx++) {
            snprintf(filename, sizeof(filename), "%s/r%d.f%d",
                     target_dir, rank, ndx);
            remove(filename);
        }
        if (unique_dir) {
            remove(target_dir);
        }    
    }

    free(target_dir);
    MPI_Finalize();
    return 0;
}
