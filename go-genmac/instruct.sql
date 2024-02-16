.open kvms.sqlite
CREATE TABLE IF NOT EXISTS virtmach (vm_mac text PRIMARY KEY,vm_name TEXT NOT NULL,vm_appident TEXT NOT NULL);
INSERT INTO virtmach(vm_mac,vm_name,vm_appident) values('52:54:00:e5:b2:00,52:54:00:e5:b2:01','0','fc-k8s-cluster');
INSERT INTO virtmach(vm_mac,vm_name,vm_appident) values('52:54:00:e5:b2:01,52:54:00:e5:b2:02','1','fc-k8s-cluster');
INSERT INTO virtmach(vm_mac,vm_name,vm_appident) values('52:54:00:e5:b2:02,52:54:00:e5:b2:03','2','fc-k8s-cluster');
INSERT INTO virtmach(vm_mac,vm_name,vm_appident) values('52:54:00:e5:b2:03,52:54:00:e5:b2:04','3','fc-k8s-cluster');
select * from virtmach;
