package gtf

import "core:os"
import "core:fmt"
import "core:strings"
import "core:path/filepath"
import "core:io"
import "core:strconv"

foreign import c "termios"
foreign import unistd "unistd" 

current_page := 0
should_close := false

navigate :: proc() {
    buf : [2]u8 = {}

    cwd := os.get_current_directory()

    fmt.println("---------------")
    fmt.println("CWD:", cwd)

    cwd_handle,_ := os.open(cwd)
    defer os.close(cwd_handle)
 
    files,err := os.read_dir(cwd_handle, 10, context.temp_allocator)

    print_string := ""
    entries_per_page := 10

    max_page := len(files) / entries_per_page
    min_page := 0
 
    for i in 0..<min(len(files), entries_per_page) {
        file := files[i + (current_page * entries_per_page)]

        if file.is_dir {
            string_path := strings.concatenate({file.name, "/"}, context.temp_allocator)

            fmt.println(i+1, ":", string_path)
        } else {
            fmt.println(i+1, ":", file.name)
        }
    }

    fmt.println("---------------")

    os.write(os.stdout, transmute([]u8)string("GTF: "))
    num_bytes,_ := os.read_full(os.stdin, buf[:])

    choice := string(buf[0:1])

    switch choice {
    case "u":
        os.set_current_directory(filepath.dir(cwd))
        current_page = 0
        break
    case "j":
        current_page = max(current_page - 1, 0)
        break
    case "k":
        current_page = min(current_page + 1, max_page)
        break
    case "q":
        should_close = true
        break
    case "e":
        buf : [4]u8 = {}
        os.write(os.stdout, transmute([]u8)string("Open Directory In: "))
        num_bytes,_ := os.read(os.stdin, buf[:]) 

        os.execvp(strings.trim_right(string(buf[:]), "\r\n"), {cwd})
        break
    case "1","2","3","4","5","6","7","8","9","0":
        choice_num := strconv.atoi(choice)

        if choice_num > len(files) {
            fmt.println("Choice", choice_num, "is too high.")
            break
        }     

        file := files[choice_num - 1]

        if file.is_dir {
            os.set_current_directory(file.fullpath)
            current_page = 0

            break
        }

        buf : [4]u8 = {}
        os.write(os.stdout, transmute([]u8)string("Open File In: "))
        num_bytes,_ := os.read(os.stdin, buf[:]) 

        os.execvp(strings.trim_right(string(buf[:]), "\r\n"), {file.fullpath})
    }

    free_all(context.temp_allocator)
}

main :: proc() {
    fmt.println("Exit: q\nPage Down:j\nPage Up: k\nDir Up: u")
    for !should_close {
        navigate()
    }

    return 
}
