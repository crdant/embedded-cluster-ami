import os
import os.path
import re
import argparse
import hashlib

def insert_properties(ovf_file, application, channel):
    with open(ovf_file, 'r') as f:
        content = f.read()

  
    # Set the OVF environment transport
    if '<VirtualHardwareSection' in content:
        pattern = r'(<VirtualHardwareSection)'
        modified_content = re.sub(pattern, f'\\1 ovf:transport="com.vmware.guestInfo"', content)

    # Property template
    property_template = """      <Property ovf:key="{key}" ovf:type="{type}" ovf:userConfigurable="true" ovf:value="{value}">
          <Label>{label}</Label>
          <Description>{description}</Description>
      </Property>"""

    # Full ProductSection template including properties
    product_section_template = """  <ProductSection ovf:required="false">
      <Info>Cloud-Init customization</Info>
      <Product>{product} Properties</Product>
{properties}
    </ProductSection>"""

    # Properties to add
    properties = [
        {
            "key": "instance-id",
            "type": "string",
            "label": "Instance Id",
            "description": "Specifies the instance id for the cloud-init",
            "value": f'id-{application}'
        },
        {
            "key": "hostname",
            "type": "string",
            "label": "Hostname",
            "description": "Specifies the hostname for the appliance",
            "value": application
        },
        {
            "key": "public-keys",
            "type": "string",
            "label": "Public SSH Keys",
            "description": "Authorized SSH public keys for the default user",
            "value": ""
        },
        {
            "key": "license-file",
            "type": "string",
            "label": "Encoded License File",
            "description": "This base64 encoded value for the appliance license file",
            "value": ""
        },
        {
            "key": "admin-password",
            "type": "string",
            "label": "Password for the Admin Console",
            "description": "Set the password for the appliance admin console",
            "value": ""
        }
    ]

    # Create property strings
    property_strings = [property_template.format(**prop) for prop in properties]
    properties_text = '\n'.join(property_strings)

    if '<ProductSection' in content:
        # Find the closing ProductSection tag and insert before it
        pattern = r'(</ProductSection>)'
        modified_content = re.sub(pattern, f'\n{properties_text}\n\\1', modified_content)
    else:
        # Find VirtualSystem closing tag and insert ProductSection before it
        pattern = r'(</VirtualSystem>)'
        product_section = product_section_template.format(
            product=application,
            properties=properties_text
        )
        modified_content = re.sub(pattern, f'{product_section}\n\\1', modified_content)

    # Write back to file
    with open(ovf_file, 'w') as f:
        f.write(modified_content)

def calculate_sha256(file_path):
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(4096):
            hasher.update(chunk)
    return hasher.hexdigest()

def replace_manifest(ovf_file):
    ovf_dir = os.path.dirname(ovf_file)
    manifest_file = "{0}.mf".format(os.path.splitext(ovf_file)[0])

    # Calculate checksums for OVF and VMDK
    ovf_content = [os.path.join(ovf_dir, f) for f in os.listdir(ovf_dir) if not f.endswith(".mf")]
    manifest_content = []
    for file in ovf_content:
        checksum = calculate_sha256(file)
        file_name = os.path.basename(file)  # Use filename, not full path
        manifest_content.append(f"SHA256({file_name})= {checksum}")

    # Write the .mf file
    with open(manifest_file, "w") as f:
        f.write("\n".join(manifest_content))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Modify an OVF template by adding properties.")
    parser.add_argument("--application", type=str, required=True, help="Application name to set in the OVF.")
    parser.add_argument("--channel", type=str, required=True, help="Channel name to set in the OVF.")
    parser.add_argument("filename", type=str, help="Filename for the OVF template.")
    
    args = parser.parse_args()
    
    output_dir = os.environ["WORK_DIR"]
    ovf_file = args.filename
    
    insert_properties(ovf_file, args.application, args.channel)
    replace_manifest(ovf_file)
