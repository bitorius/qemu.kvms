package main

import (
	"crypto/rand"
	"fmt"
	"strconv"
)

func main() {
	buf := make([]byte, 6)
	// Set the local bit
	//buf[0] |= 2
	buf[0] = 82
	buf[1] = 84
	buf[2] = 0
	buf[3] = 229
	appName := "fc-k8s-cluster"
	appIdent := make([]byte, 1)
	_, err := rand.Read(appIdent)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	buf[4] = appIdent[0]
	fmt.Printf(".open kvms.sqlite\n")
	fmt.Printf("CREATE TABLE IF NOT EXISTS virtmach (vm_mac text PRIMARY KEY,vm_name TEXT NOT NULL,vm_appident TEXT NOT NULL);\n")
	for x := 0; x < 4; x++ {
		buf[5] = byte(x)
		fmt.Printf("INSERT INTO virtmach(vm_mac,vm_name,vm_appident) values('%02x:%02x:%02x:%02x:%02x:%02x','%s','%s');\n", buf[0], buf[1], buf[2], buf[3], buf[4], buf[5], strconv.Itoa(x),appName)
	}
	fmt.Printf("select * from virtmach;\n")
}
