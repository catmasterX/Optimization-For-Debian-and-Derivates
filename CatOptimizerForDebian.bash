#!/bin/bash

# Script de optimización de rendimiento para Linux

# Parte 1: Optimizaciones del sistema

echo "Optimizando el rendimiento del sistema..."

# Actualiza la lista de paquetes e instala actualizaciones
sudo apt update
sudo apt upgrade -y

# Limpia el sistema eliminando paquetes huérfanos y archivos temporales
sudo apt autoremove -y
sudo apt clean

# Aumenta la cantidad de inodos reservados para mejorar el rendimiento del sistema de archivos
sudo tune2fs -m 1 /dev/sda1

# Aumenta el límite de archivos abiertos para permitir más conexiones simultáneas
echo "*                -    nofile        65535" | sudo tee -a /etc/security/limits.conf
echo "root             -    nofile        65535" | sudo tee -a /etc/security/limits.conf

# Deshabilita el acceso a la papelera de reciclaje
echo "alias rm='rm -i'" >> ~/.bashrc
source ~/.bashrc

# Habilita la compresión de memoria RAM
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Deshabilita la resolución de nombres mDNS (puede mejorar la velocidad de red)
echo "DNSSEC=no" | sudo tee -a /etc/systemd/resolved.conf
sudo systemctl restart systemd-resolved

# Habilita TRIM para unidades SSD
sudo systemctl enable fstrim.timer

# Desactivar el inicio de algunos servicios al arrancar el sistema

systemctl disable cups
systemctl disable bluetooth

# Deshabilita el informe de errores automáticos
sudo sed -i 's/enabled=1/enabled=0/' /etc/default/apport

# Deshabilita las sugerencias y búsquedas en línea de Ubuntu
gsettings set com.canonical.Unity.Lenses remote-content-search none

# Deshabilita la opción "Enviar información de uso a Canonical"
gsettings set com.canonical.Unity.ApplicationsLens display-available-apps false
gsettings set com.canonical.Unity.ApplicationsLens display-recent-apps false
gsettings set com.canonical.Unity.ApplicationsLens display-frequent-apps false

# Limpia la caché de miniaturas
rm -r ~/.cache/thumbnails/*

# Ajustar el valor swappiness
echo "Ajustando el valor swappiness..."
sysctl -w vm.swappiness=10

# Desactivar el acceso a la fecha de acceso de los archivos (atime)
echo "Desactivando el acceso a la fecha de acceso de los archivos (atime)..."
for mount in $(mount | awk '$3 == "ext4" {print $3}'); do
    tune2fs -o ^atime $mount
done

# Liberar memoria RAM
echo "Liberando memoria RAM..."
sync; echo 3 > /proc/sys/vm/drop_caches

# Desactivar servicios innecesarios (ajusta según tu distribución)
# systemctl disable <nombre_del_servicio>

# Ajustar la política de escritura de disco para mejorar la velocidad (requiere hdparm)
echo "Ajustando la política de escritura de disco..."
hdparm -W1 /dev/sdX

# Aumentar el número máximo de archivos que pueden ser abiertos simultáneamente
echo "Aumentando el número máximo de archivos abiertos..."
ulimit -n 65536

# Incrementar el número máximo de procesos del sistema
echo "Incrementando el número máximo de procesos del sistema..."
sysctl -w kernel.pid_max=4194304

# Desactivar la grabación de sesiones (si no es necesario)
echo "Desactivando la grabación de sesiones..."
systemctl disable auditd

# Parte 2: Optimizaciones de la red

echo "Optimizando la red..."

# Ajustar el tamaño del búfer de recepción y envío
echo "Ajustando el tamaño del búfer de recepción y envío..."
sysctl -w net.ipv4.tcp_rmem="4096 65536 16777216"
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216"

# Aumentar el límite de puertos efímeros disponibles
echo "Aumentando el límite de puertos efímeros..."
sysctl -w net.ipv4.ip_local_port_range="1024 65000"

# Incrementar el límite de conexiones concurrentes
echo "Incrementando el límite de conexiones concurrentes..."
sysctl -w net.ipv4.netfilter.ip_conntrack_max=1048576

# Desactivar el escalado automático de ventanas TCP
echo "Desactivando el escalado automático de ventanas TCP..."
sysctl -w net.ipv4.tcp_window_scaling=0

# Desactivar el control de congestión de BIC
echo "Desactivando el control de congestión de BIC..."
sysctl -w net.ipv4.tcp_congestion_control=bic

# Incrementar el límite de puertos disponibles para IPv4
echo "Incrementando el límite de puertos disponibles para IPv4..."
sysctl -w net.ipv4.ip_local_port_range="1024 65535"

# Ajustar el valor de "dirty writeback" para reducir la frecuencia de escritura al disco
echo "Ajustando el valor de 'dirty writeback'..."
sysctl -w vm.dirty_writeback_centisecs=1500

sudo apt update
sudo apt upgrade

sudo apt install xserver-xorg-video-amdgpu mesa-vulkan-drivers mesa-opencl-icd
sudo apt install xserver-xorg-video-intel mesa-vulkan-drivers mesa-opencl-icd

echo "Habilitando zram..."
sudo modprobe zram
echo "zstd" | sudo tee /sys/block/zram0/comp_algorithm
echo "2G" | sudo tee /sys/block/zram0/disksize
sudo mkswap /dev/zram0
sudo swapon /dev/zram0

# Configurar gobernador del CPU en máximo rendimiento
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "performance" > "$cpu"
done

# Configurar preemption model en baja latencia
sysctl -w kernel.preempt_lowlatency=1

# Configurar performance level para tarjetas de video
echo "Configurando performance level para tarjetas de video..."
echo "high" > /sys/class/drm/card0/device/power_dpm_force_performance_level
echo "high" > /sys/class/drm/card1/device/power_dpm_force_performance_level

# Guardar el gobernador en máximo rendimiento en archivo de inicio
echo -e "# Configurar el gobernador del CPU en máximo rendimiento\nfor cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do\necho \"performance\" > \"\$cpu\"\ndone" | sudo tee -a /etc/rc.local

# Guardar el preemption model en baja latencia en archivo de sysctl
echo "kernel.preempt_lowlatency=1" | sudo tee -a /etc/sysctl.d/99-lowlatency.conf

# Guardar la configuración del performance level para tarjetas de video
echo "echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level" | sudo tee -a /etc/rc.local
echo "echo high > /sys/class/drm/card1/device/power_dpm_force_performance_level" | sudo tee -a /etc/rc.local

sudo update-grub

echo "Optimización completada."
echo "Por Favor Reinicia tu Sistema"
