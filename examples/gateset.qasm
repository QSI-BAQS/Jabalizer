OPENQASM 2.0;
include "qelib1.inc";
qreg q[3];
t q[0];
h q[1];
tdg q[2];
rz(0) q[0];
cx q[1],q[2];
rz(pi/2) q[1];