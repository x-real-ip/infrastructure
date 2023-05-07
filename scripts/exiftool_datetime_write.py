#!/bin/python3
import os
import subprocess

# Set the path of the folder you want to loop through
folder_path = './photos/'

# Set the list of file extensions you want to search for
extensions = ['.jpg', '.jpeg', '.png', '.gif', '.mp4']


# Delete file without "_bewerkt" if thers is a "_bewerkt" version of the same file
for filename in os.listdir(folder_path):
    if "-bewerkt" in filename:
        # Remove the "-bewerkt" substring to get the original filename
        original_filename = filename.replace("-bewerkt", "")
        # Check if the original file exists
        if os.path.exists(os.path.join(folder_path, original_filename)):
            # Delete the original file if the modified file exists
            os.remove(os.path.join(folder_path, original_filename))


# # Loop through all files in the folder
# # filename must be YYYYMMDD_HHMMSS.EXTENSION
# for filename in os.listdir(folder_path):
#     # Get the file extension of the current file
#     file_ext = os.path.splitext(filename)[1].lower()
#     # Check if the file extension is in the list of extensions
#     if file_ext in extensions:

#         year = filename[:4]
#         month = filename[4:6]
#         day = filename[6:8]
#         hour = filename[9:11]
#         minute = filename[11:13]
#         second = filename[13:15]

#         datetime_exifstr = year + ":" + month + ":" + \
#             day + "-" + hour + ":" + minute + ":" + second
#         print(datetime_exifstr)

#         # # Fix corrupted exifdata
#         # command = ["exiftool", "-all=", "-tagsfromfile", "@", "-all:all", "--padding", "-unsafe" +
#         #            datetime_exifstr, os.path.join(folder_path, filename)]
#         # subprocess.run(command)

#         # set the DateTimeOriginal tag to the date/time information
#         command = ["exiftool", "-DateTimeOriginal=" + datetime_exifstr, "-CreateDate=" +
#                    datetime_exifstr, os.path.join(folder_path, filename)]
#         subprocess.run(command)
