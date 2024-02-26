function hexStringFromData(data, dataLen) {
  let hexStr = '';

  for (let i = 0; i < dataLen; i++) {
    const char = data.charAt(i);
    hexStr += char.charCodeAt(0).toString(16);
  }  
  return hexStr;
}

function HexStringFromData() {
  const data = '1234567890abcdef12345678';
  const dataLen = data.length;
  const hexStr = hexStringFromData(data, dataLen);
  console.log('0x' + hexStr); 
}

HexStringFromData();
