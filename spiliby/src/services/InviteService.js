import QRCode from 'qrcode';

const QR_LIMIT = 1400;

const loadImage = (dataUrl) => new Promise((resolve, reject) => {
  const image = new Image();
  image.onload = () => resolve(image);
  image.onerror = () => reject(new Error('Could not load the selected image.'));
  image.src = dataUrl;
});

export const InviteService = {
  buildSharePayload: (data) => {
    const trimmed = {
      profile: data.profile || [],
      friends: data.friends || [],
      groups: data.groups || [],
      groupMembers: data.groupMembers || [],
      expenses: data.expenses || [],
      settlements: data.settlements || [],
    };
    const payload = JSON.stringify(trimmed);
    if (payload.length > QR_LIMIT) {
      throw new Error('This backup is too large for a single QR code. Try sharing a smaller group or use the JSON export option.');
    }
    return payload;
  },

  generateInviteQr: async (data) => {
    const payload = InviteService.buildSharePayload(data);
    return QRCode.toDataURL(payload, {
      margin: 1,
      width: 320,
      color: { dark: '#0d1321', light: '#ffffff' },
    });
  },

  redeemInviteQr: async (imageDataUrl) => {
    const image = await loadImage(imageDataUrl);
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');

    if (!context) {
      throw new Error('Unable to read QR image data.');
    }

    canvas.width = image.width;
    canvas.height = image.height;
    context.drawImage(image, 0, 0, canvas.width, canvas.height);

    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
    const { default: jsQR } = await import('jsqr');
    const code = jsQR(imageData.data, imageData.width, imageData.height);

    if (!code) {
      throw new Error('No QR code was found in the selected image.');
    }

    return code.data;
  },
};
