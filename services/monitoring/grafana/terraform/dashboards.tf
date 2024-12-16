// Import subfolders using an external script
data "external" "subfolders" {
  program = ["bash", "${path.module}/../../../../scripts/tf_helper_list_subfolders.sh", "${path.module}/../assets/shared/dashboards"]
}

// Local mappings of folder names to their paths
locals {
  folder_map = data.external.subfolders.result
}

// Create Grafana folders for each subfolder
resource "grafana_folder" "subfolders" {
  for_each = local.folder_map

  title = each.key // Use each.key to access each folder's name
}

// Function to list all JSON files within a directory
data "external" "dashboard_files" {
  for_each = local.folder_map

  program = ["bash", "${path.module}/../../../../scripts/tf_helper_list_json_files_in_folder.sh", "${path.module}/../assets/shared/dashboards/${each.key}"]
}

// Create Grafana dashboards from JSON files
resource "grafana_dashboard" "dashboards" {
  for_each = toset(flatten([
    for folder_name in keys(local.folder_map) : [
      for file in values(data.external.dashboard_files[folder_name].result) : "${folder_name},${file}"
    ]]
  ))
  # CSV approach
  config_json = jsonencode(jsondecode(file(split(",", each.value)[1])).dashboard)
  folder      = grafana_folder.subfolders[split(",", each.value)[0]].id
}
