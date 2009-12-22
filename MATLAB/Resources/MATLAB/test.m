function result = test(img);
f = [1 1 1; 1 -8 1; 1 1 1];
result = conv2(img, f, 'valid') - conv2(img, f*(-1), 'valid');
