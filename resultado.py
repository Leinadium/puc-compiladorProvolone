X = int(input("Entrada [X]:"))
Y = int(input("Entrada [Y]:"))
Z = 0
if X > 0:
	Z += 1
else:
	if Y > 0:
		Z += 1
		Z += 1
	else:
		Z += 1
		Z += 1
		Z += 1
print("Saida: [Z] = %d\n" % Z)
