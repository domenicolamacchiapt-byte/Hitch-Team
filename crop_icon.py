import sys
import os
try:
    from PIL import Image
except ImportError:
    os.system('pip3 install Pillow --break-system-packages')
    from PIL import Image

img_path = 'assets/icon.png'
img = Image.open(img_path)
w, h = img.size
# Togliamo il 15% di bordo nero da tutti i lati
crop_p = 0.15
left = int(w * crop_p)
top = int(h * crop_p)
right = int(w * (1 - crop_p))
bottom = int(h * (1 - crop_p))

cropped = img.crop((left, top, right, bottom))
# Ridimensioniamola a 512x512
cropped = cropped.resize((512, 512), Image.Resampling.LANCZOS if hasattr(Image, 'Resampling') else Image.LANCZOS)

# Salva per sovrascrivere tutto
cropped.save('assets/icon.png')

if not os.path.exists('web/icons'):
    os.makedirs('web/icons')

cropped.save('web/favicon.png')
cropped.resize((192, 192), Image.Resampling.LANCZOS if hasattr(Image, 'Resampling') else Image.LANCZOS).save('web/icons/Icon-192.png')
cropped.save('web/icons/Icon-512.png')
cropped.resize((192, 192), Image.Resampling.LANCZOS if hasattr(Image, 'Resampling') else Image.LANCZOS).save('web/icons/Icon-maskable-192.png')
cropped.save('web/icons/Icon-maskable-512.png')

print('Icone aggiornate e ritagliate con successo!')
