provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_virtual_network" "example-vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location              = "West US"
  resource_group_name   = "azurepipelinesrg"

  tags = {
    Environment = "dev"
  }
}


resource "azurerm_subnet" "example-subnet" {
  name                 = "example-subnet"
  resource_group_name   = "azurepipelinesrg"
  virtual_network_name = azurerm_virtual_network.example-vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  depends_on = [azurerm_virtual_network.example-vnet]
}

# Create a public IP for the VM
resource "azurerm_public_ip" "main" {
  name                = "myPublicIP"
  location              = "West US"
  resource_group_name   = "azurepipelinesrg"
  allocation_method   = "Dynamic"

  tags = {
    Environment = "dev"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "myNIC"
  location              = "West US"
  resource_group_name   = "azurepipelinesrg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    Environment = "dev"
  }

  depends_on = [azurerm_subnet.example-subnet]
}

# Create a VM
resource "azurerm_virtual_machine" "vm1" {
  name                  = "vm1"
  location              = "West US"
  resource_group_name   = "azurepipelinesrg"
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true


  storage_os_disk {
    name              = "myOSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vm1"
    admin_username = "adminuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    Environment = "dev"
  }
}
