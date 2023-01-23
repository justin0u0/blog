!/bin/bash

images=$(ls | grep ".png")
echo $images

for image in $images
do
	fileName=$(echo $image | cut -d'.' -f1)
	fileExt=$(echo $image | cut -d'.' -f2)
	ffmpeg -i $image -vf scale=1440:-1 "$fileName-resized.$fileExt"
	mv "$fileName-resized.$fileExt" $image
done
