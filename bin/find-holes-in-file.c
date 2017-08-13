/**
 * Find holes in files, often caused by data degradation in disks.
 *
 * A hole is a sequential area within a file whose bytes are all zeroes.
 * Only holes of at least an specified minimum size (256 kiB by default)
 * are reported.
 *
 * Compile with:
 *  gcc find-holes-in-file.c -o find-holes-in-file -Wall -pedantic -O2 -g
 *
 * MIT License
 *
 * Copyright (c) (c) 2017 Alicia Boya García
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <getopt.h>
#include <stdbool.h>
#include <errno.h>
#include <inttypes.h>

#ifdef __GNUC__
/* GCC is better at choosing branches that me. */
#define likely(x)       x
#define unlikely(x)     x
#else
/* On the other hand, clang can use a bit of help. */
#define likely(x)       __builtin_expect((x),1)
#define unlikely(x)     __builtin_expect((x),0)
#endif

#define FGETC_BUFFER_SIZE 512

size_t min_hole_size = 256 * 1024;

size_t parse_size(const char *size_str) {
    /* https://stackoverflow.com/a/16108037/1777162 */
    const char *endp = size_str;
    int sh;
    errno = 0;
    uintmax_t x = strtoumax(size_str, (char**)&endp, 10);
    if (errno || endp == size_str) goto error;
    switch(*endp) {
    case 'k': sh=10; break;
    case 'M': sh=20; break;
    case 'G': sh=30; break;
    case 0: sh=0; break;
    default: goto error;
    }
    if (x > SIZE_MAX>>sh) goto error;
    x <<= sh;
    return (size_t) x;

error:
    fprintf(stderr, "Could not parse size string: %s\n", size_str);
    exit(2);
}

void show_usage_and_exit() {
    fprintf(stderr, "Usage: find-holes-in-file [--min-hole-size <size>] <file>\n");
    exit(2);
}

void __attribute__ ((noinline)) report_hole(const char* file_name, size_t position, size_t hole_size) {
    printf("%s: Found hole at 0x%lx of %lu bytes (0x%lx bytes, %g kiB)\n",
            file_name, position, hole_size, hole_size, (double) hole_size / 1024.0);
    fflush(stdout); /* immediate feedback when piped to tee */
}

/* >100% speedup compared to fgetc() from libc */
int inline static fast_fgetc(FILE *fp) { /* 25% additional speedup with `static` */
    static unsigned char buffer[FGETC_BUFFER_SIZE];
    static const unsigned char *buffer_position = buffer;
    static const unsigned char *buffer_end = buffer;

    if (unlikely(buffer_position == buffer_end)) {
        /* fill the buffer */
        int bytes_read = fread(buffer, 1, FGETC_BUFFER_SIZE, fp);
        if (unlikely(bytes_read == 0))
            return EOF;

        buffer_position = buffer;
        buffer_end = buffer + bytes_read;
    }

    int ret = *(buffer_position);
    buffer_position++;
    return ret;
}

void find_holes_in_file(const char* file_name, 
                        bool *found_holes, 
                        bool *io_error_occurred) 
{
    FILE *fp = fopen(file_name, "rb");
    if (!fp) {
        perror(NULL);
        *io_error_occurred = true;
        return;
    }

    size_t pos = 0;
    ssize_t current_hole_start = -1; /* -1 if not currently in a hole. */
    int read_byte;

    do {
        read_byte = fast_fgetc(fp);

        if (unlikely(unlikely(read_byte == '\0') && likely(current_hole_start < 0))) {
            /* enter in "within hole" state */
            current_hole_start = pos;
        } else if (unlikely(likely(read_byte != '\0') && current_hole_start >= 0)) {
            size_t hole_size = pos - current_hole_start;
            if (unlikely(hole_size >= min_hole_size)) {
                *found_holes = true;
                size_t hole_start_pos = pos - hole_size;
                report_hole(file_name, hole_start_pos, hole_size);
            }

            /* return to "not in hole" state */
            current_hole_start = -1;
        }
        pos++;
    } while (read_byte != EOF);

    /* Show an error if the EOF was returned due to a I/O error. */
    if (errno) {
        perror(NULL);
        *io_error_occurred = true;
    }

    if (0 != fclose(fp)) {
        perror(NULL);
        *io_error_occurred = true;
    }
}

int main(int argc, char** argv) {
    int c;

    while (1) {
        int option_index = 0;
        static struct option long_options[] = {
            {"help",            no_argument,       NULL, 'h'},
            {"min-hole-size",   required_argument, NULL, 'm'},
            {0,                 0,                 NULL, 0}
        };

        c = getopt_long(argc, argv, "hm:", 
                long_options, &option_index);
        if (c == -1)
            break;

        switch (c) {
        case 'h':
            show_usage_and_exit();
        case 'm':
            min_hole_size = parse_size(optarg);
            break;
        default:
            abort();
        }

    }

    if (optind >= argc) {
        show_usage_and_exit();
    }

    bool found_holes = false;
    bool found_io_errors = false;
    while (optind < argc) {
        const char* file_name = argv[optind++];
        find_holes_in_file(file_name, &found_holes, &found_io_errors);
    }

    if (found_io_errors) {
        return 2;
    } else if (found_holes) {
        return 1;
    } else {
        return 0;
    }
}
