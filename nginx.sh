cat > nginx-demo.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
        - image: nginx
          name: nginx
          ports:
            - containerPort: 80
              protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
spec:
  clusterIP: 10.109.179.231
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    run: nginx
  type: ClusterIP
EOF

kubectl apply -f nginx-demo.yaml
