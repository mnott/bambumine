#!/bin/sh

show_help() {
    echo "Usage: $(basename $0) [OPTION]"
    echo "Manage NAT and printer firewall rules"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -D, --delete   Delete all rules"
    echo "  -s, --show     Show current rules"
    echo ""
    echo "Without options, rules will be added (default behavior)"
}

show_rules() {
    echo "=== NAT Rules (PREROUTING) ==="
    iptables -t nat -L PREROUTING -n --line-numbers
    echo ""
    echo "=== Firewall Rules ==="
    echo "INPUT chain:"
    iptables -L INPUT -n --line-numbers
    echo ""
    echo "OUTPUT chain:"
    iptables -L OUTPUT -n --line-numbers
    echo ""
    echo "FORWARD chain:"
    iptables -L FORWARD -n --line-numbers
}

# Process command line options
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -s|--show)
        show_rules
        exit 0
        ;;
    -D|--delete)
        ACTION="D"
        ;;
    "")
        ACTION="A"
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

logger -s -t "($(basename $0))" $$ "Setting NAT rules... (Action: $ACTION)"


# Printer access rules
if [ "$ACTION" = "D" ]; then
    # Delete printer rules
    iptables -D INPUT   -s 192.168.1.0/24  -d 192.168.1.252  -j ACCEPT 2>/dev/null
    iptables -D OUTPUT  -d 192.168.1.0/24  -s 192.168.1.252  -j ACCEPT 2>/dev/null
    iptables -D FORWARD -s 192.168.1.252 ! -d 192.168.1.0/24 -j DROP   2>/dev/null
    iptables -D OUTPUT  -s 192.168.1.252 ! -d 192.168.1.0/24 -j DROP   2>/dev/null
else
    # Add printer rules
    iptables -A INPUT   -s 192.168.1.0/24  -d 192.168.1.252  -j ACCEPT
    iptables -A OUTPUT  -d 192.168.1.0/24  -s 192.168.1.252  -j ACCEPT
    iptables -A FORWARD -s 192.168.1.252 ! -d 192.168.1.0/24 -j DROP
    iptables -A OUTPUT  -s 192.168.1.252 ! -d 192.168.1.0/24 -j DROP
fi

logger -s -t "($(basename $0))" $$ "...done."

# Show the current rules after changes if we're not in help or show mode
if [ "$ACTION" = "A" ] || [ "$ACTION" = "D" ]; then
    echo "Current rules after changes:"
    show_rules
fi