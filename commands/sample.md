# This is the test 

### testing6

## test

This is a test command.

This second paragraph won't be displayed on the command list.

```bash
echo "Hello, World!"
```

## test-using-kumander

This is a command that runs commands on the same file recursively e.g `kumander tests test`

```bash
# Run the test command in the same file
kumander sample test
```

## whatstheweather

Display the weather in Atlanta.

```bash
curl "wttr.in/Atlanta?format=%t" && echo
```

## whatsmyip

Display your public IP address.

```bash
echo "ipconfig.me:"
curl ifconfig.me && echo
echo "checkip.amazonaws.com:"
curl https://checkip.amazonaws.com && echo
```

## whats

Display the weather in Atlanta and your public IP address (demo on using multiple commands in the same file).

```bash
kumander sample whatstheweather
kumander sample whatsmyip
```

## sysinfo

Display system information including OS, CPU, and memory.

```bash
echo "OS: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "CPU: $(lscpu | grep 'Model name' | cut -f 2 -d ":")"
echo "Memory: $(free -h | awk '/^Mem:/ {print $2}')"
```

## dockermanage

List, start, or stop Docker containers (demo on using variables).

```bash
case "$1" in
    list)
        docker ps -a
        ;;
    start)
        docker start "$2"
        ;;
    stop)
        docker stop "$2"
        ;;
    *)
        echo "Usage: dockermanage [list|start|stop] [container_name]"
        ;;
esac
```