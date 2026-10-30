output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "installer_image" {
  description = "Image for `talosctl upgrade --image ...`."
  value       = data.talos_image_factory_urls.this.urls.installer
}
