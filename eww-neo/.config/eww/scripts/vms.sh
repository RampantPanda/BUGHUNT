ssh pekka@oxbacka '
    r=$(virsh list --name | grep -c .)
    t=$(virsh list --all --name | grep -c .)
    printf "VM %s/%s\n" "$r" "$t"
'
