for i in 4000, 4001, 4002, 4500, 5000, 8080, 9000; do
    echo "=== $i ==="
    lsof -i tcp:$i
done