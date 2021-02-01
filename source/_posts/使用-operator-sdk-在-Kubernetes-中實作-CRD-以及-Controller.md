---
title: 使用 operator-sdk 在 Kubernetes 中實作 CRD 以及 Controller
date: 2021-02-01 18:32:14
tags:
  - Kubernetes
  - operator-sdk
  - Golang
categories: Kubernetes
---

# 目標

使用 operator-sdk 建立一個 CustomResourceDefinition，類似於 ReplicaSet 的功能，在這裡筆者將他稱為 PodSet。

PodSet 可以自動的創建 Replicas 的數量個 Pods，並且在 Pods 被新增、刪除，或是 PodSet 的 Spec 被修改時自動增減 Pods 的數量。

先附上 PodSet 的 Spec：

```yaml
apiVersion: k8stest.justin0u0.com/v1alpha1
kind: PodSet
metadata:
  name: podset-sample
spec:
  # Add fields here
  replicas: 2
```

程式碼的部分在：[https://github.com/justin0u0/podset-operator](https://github.com/justin0u0/podset-operator)

# Prerequisites

筆者的環境如下：

```markdown
- Minikube v1.16.0
- Kubernetes v1.18.3
- operator-sdk v1.3.0
- golang 1.15.7
- Docker 20.10.2
```

## Installation

### operator-sdk

```bash
brew install operator-sdk

operator-sdk version: "v1.3.0", commit: "1abf57985b43bf6a59dcd18147b3c574fa57d3f6", kubernetes version: "v1.19.4", go version: "go1.15.6", GOOS: "darwin", GOARCH: "amd64"
```

### golang

```bash
brew install golang-go

go version
go version go1.15.7 darwin/amd64
```

# Create new project

```bash
mkdir podset-operator && cd podset-operator

operator-sdk init --domain=justin0u0.com --repo=github.com/justin0u0/podset-operator
```

# Create new API and Controller

我們 Create 一個新的 Resource 其中 `group=k8stest`，`version=v1alpha1`，`kind=PodSet`。

```bash
operator-sdk create api --group=k8stest --version=v1alpha1 --kind=PodSet
Create Resource [y/n]
y
Create Controller [y/n]
y
```

完成後目錄結構應該如下：

```
.
├── Dockerfile
├── Makefile
├── PROJECT
├── api
│   └── v1alpha1
│       ├── groupversion_info.go
│       ├── podset_types.go
│       └── zz_generated.deepcopy.go
├── bin
│   ├── controller-gen
│   ├── kustomize
│   └── manager
├── config
│   ├── certmanager
│   │   ├── certificate.yaml
│   │   ├── kustomization.yaml
│   │   └── kustomizeconfig.yaml
│   ├── crd
│   │   ├── bases
│   │   │   └── k8stest.justin0u0.com_podsets.yaml
│   │   ├── kustomization.yaml
│   │   ├── kustomizeconfig.yaml
│   │   └── patches
│   │       ├── cainjection_in_podsets.yaml
│   │       └── webhook_in_podsets.yaml
│   ├── default
│   │   ├── kustomization.yaml
│   │   ├── manager_auth_proxy_patch.yaml
│   │   └── manager_config_patch.yaml
│   ├── manager
│   │   ├── controller_manager_config.yaml
│   │   ├── kustomization.yaml
│   │   └── manager.yaml
│   ├── prometheus
│   │   ├── kustomization.yaml
│   │   └── monitor.yaml
│   ├── rbac
│   │   ├── auth_proxy_client_clusterrole.yaml
│   │   ├── auth_proxy_role.yaml
│   │   ├── auth_proxy_role_binding.yaml
│   │   ├── auth_proxy_service.yaml
│   │   ├── kustomization.yaml
│   │   ├── leader_election_role.yaml
│   │   ├── leader_election_role_binding.yaml
│   │   ├── podset_editor_role.yaml
│   │   ├── podset_viewer_role.yaml
│   │   ├── role.yaml
│   │   └── role_binding.yaml
│   ├── samples
│   │   ├── k8stest_v1alpha1_podset.yaml
│   │   └── kustomization.yaml
│   └── scorecard
│       ├── bases
│       │   └── config.yaml
│       ├── kustomization.yaml
│       └── patches
│           ├── basic.config.yaml
│           └── olm.config.yaml
├── controllers
│   ├── podset_controller.go
│   └── suite_test.go
├── cover.out
├── go.mod
├── go.sum
├── hack
│   └── boilerplate.go.txt
├── main.go
└── testbin
    ├── bin
    │   ├── etcd
    │   ├── kube-apiserver
    │   └── kubectl
    └── setup-envtest.sh
```

其中比較重要的幾個部分有 `main.go`，`api/podset_types.go` 以及 `controllers/podset_controller.go`。

## Define API

在 `api/podset_types.go` 中，會看到這樣的一段 Code：

```go
// PodSetSpec defines the desired state of PodSet
type PodSetSpec struct {
  // INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
  // Important: Run "make" to regenerate code after modifying this file

  // Foo is an example field of PodSet. Edit PodSet_types.go to remove/update
  Foo string `json:"foo,omitempty"`
}

// PodSetStatus defines the observed state of PodSet
type PodSetStatus struct {
  // INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
  // Important: Run "make" to regenerate code after modifying this file
}
```

其中 `PodSetSpec` 是用來定義 User 給定的 Yaml 中，`Spec` 的部分要長成什麼樣子。因此我們將 `Foo` 刪除加上 `Replicas`。[在 `PodSetSpec` 中，可以透過 `+kubebuilder:validation` 的 Marker 來驗證欄位。](https://book.kubebuilder.io/reference/generating-crd.html#validation)

```go
type PodSetSpec struct {
  Replicas int32 `json:"replicas"`
}
```

而 `PodSetStatus` 是用來紀錄 Runtime 時的狀態，比如說可以紀錄屬於這個 PodSet 的 Pod 有哪些，以及真正的 `Replicas` 的值。另外，在 `PodSetStatus` 上加上 `+kubebuilder:subresource:status`，更新主資源不會修改到 `Status`，同樣地，更新 `Status` 不會更新到主資源。

```go
// +kubebuilder:subresource:status
type PodSetStatus struct {
  Replicas int32    `json:"replicas"`
  PodNames []string `json:"pod_names"`
}
```

若不清楚 `Spec` 與 `Status` 的關係，可以參考 [Spec & Status](https://www.notion.so/Spec-Status-67292b8b3a904121877af8de9361204a)。

修改 API 後，要記得執行 `make generate` 以更新 generated code。

## Generate CRD Manifests

完成 `PodSetSpec` 後，operator-sdk 可以根據 `PodSetSpec` 產生出部署用的 yaml file。

執行 `make manifests`，會看到 `config/crd/bases/k8stest.justin0u0.com_podsets.yaml` 的生成，這個 Config 是給 Kubernetes 用來驗證你寫的 `PodSet` 是否為正確的用的。

## Implement the Controller

Controller 負責處理整個 CRD 的邏輯，在 `controllers/podset_controller.go` 中，有兩個重要的部分。

### SetupWithManager

```go
// SetupWithManager sets up the controller with the Manager.
func (r *PodSetReconciler) SetupWithManager(mgr ctrl.Manager) error {
  return ctrl.NewControllerManagedBy(mgr).
    For(&k8stestv1alpha1.PodSet{}).
    Complete(r)
}
```

在 `SetupWithManager` 中，會看到這樣一段程式碼，其中 `For(&k8stestv1alpha1.PodSet)` 代表最主要要觀察的 Resource 是 `PodSet` 這個 Resource，所謂觀察也就是只當有任何 `PodSet` 的 Create, Update, Delete 事件，都會送出一個 **Reconcile** Request，而 **Reconcile** 正是等一下會實作的 Controller Logic。

不過不只是在 `PodSet` Create, Update, Delete 時需要 Reconcile，在我們想要做的 `PodSet` 例子中，當由 `PodSet` 管理的 `Pod` 有 Create, Update, Delete 的事件時，也應該要做出對應的處理。

因此可以將 `SetupWithManager` 函數改成以下：

```go
// SetupWithManager sets up the controller with the Manager.
func (r *PodSetReconciler) SetupWithManager(mgr ctrl.Manager) error {
  return ctrl.NewControllerManagedBy(mgr).
    For(&k8stestv1alpha1.PodSet{}).
    Owns(&corev1.Pod{}).
    Complete(r)
}
```

其中的 `Owns(&corev1.Pod{})` 代表 `PodSet` 會 Own 類別為 `corev1.Pod` 的 resource，並且，在 `corev1.Pod` 這種 resource 被 Create, Update, Delete 時，會送一個 Reconcile Request 給他的 Owner，也就是 `PodSet`。

### Reconcile

```go
// +kubebuilder:rbac:groups=k8stest.justin0u0.com,resources=podsets,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=k8stest.justin0u0.com,resources=podsets/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=k8stest.justin0u0.com,resources=podsets/finalizers,verbs=update

func (r *PodSetReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
  _ = r.Log.WithValues("podset", req.NamespacedName)

  // your logic here

  return ctrl.Result{}, nil
}
```

首先，Reconcile 的回傳值有 `ctrl.Result` 與 `error` 兩個。當 `ctrl.Result` 回傳 `{Requeue: true}` 或是 `error != nil` 的話，Controller 會 requeue reconcile 的請求以重新執行一遍 Reconcile。

再來，看到 `Reconcile` 上方的註解，代表 Controller 所擁有的 RBAC 權限。可以看到預設的 RBAC 權限包含對 `PodSet` 資源的 get, list, watch, create...。在 `PodSet` 中，需要權限來新增、刪除、取得 Pods，觀察 Pod 的刪減...權限，因此加上 Pod 的權限：

```go
// +kubebuilder:rbac:groups=core,resources=pods,verbs=get;list;create;delete;watch
```

接個開始實踐 `PodSet` 邏輯。首先，應該先找到發起請求的 `PodSet`：

```go
// Fetch podset instance
podSet := &k8stestv1alpha1.PodSet{}
if err := r.Get(ctx, req.NamespacedName, podSet); err != nil {
  if errors.IsNotFound(err) {
    // Request object not found, could have been deleted after reconcile request.
    // Owned objects are automatically garbage collected. For additional cleanup logic use finalizers.
    // Return and don't requeue
    log.Info("PodSet resource not found. Ingoring since object must be deleted.")
    return ctrl.Result{}, nil
  }
  // Error reading object - requeue the requst
  log.Error(err, "Failed to get PodSet resource.")
  return ctrl.Result{}, err
}
```

`r.Get` 其實也等於 `r.client.Get`，`r` 是一個 `PodSetReconciler`，看一下 `PodSetReconciler` 的定義：

```go
// PodSetReconciler reconciles a PodSet object
type PodSetReconciler struct {
  client.Client
  Log    logr.Logger
  Scheme *runtime.Scheme
}
```

可以看到包含一個 `client.Client`，這是 Golang struct 中的 [promoted field](https://www.notion.so/Golang-7ab921d39bde41c998e39ece6c88ef40)，因此可以直接用 `client.Client` 內的 method，例如 `r.Get`, `r.List`...等等。

再來，可以先預想一下生成由 `PodSet` 管理、生成出來的 Pod 要有怎麼樣的 Spec，以方便管理，因此筆者先實作 `podForPodSet` 函數，給定一個 `PodSet`，`podForPodSet` 函數回傳一個 Pod。

```go
func (r *PodSetReconciler) podForPodSet(podSet *k8stestv1alpha1.PodSet) *corev1.Pod {
  labels := map[string]string{
    "app":       "podset",
    "podset_cr": podSet.Name,
  }

  pod := &corev1.Pod{
    ObjectMeta: metav1.ObjectMeta{
      Name:      podSet.Name + "-" + strconv.FormatInt(time.Now().UnixNano(), 36),
      Namespace: podSet.Namespace,
      Labels:    labels,
    },
    Spec: corev1.PodSpec{
      Containers: []corev1.Container{
        {
          Name:    "busybox",
          Image:   "busybox",
          Command: []string{"sleep", "3600"},
        },
      },
    },
  }

  ctrl.SetControllerReference(podSet, pod, r.Scheme)
  return pod
}
```

可以看到，產生出來的 Pod 有 labels `{"app": "podset", "podset_cr": podSet.Name}` 這樣的標籤，這個標籤可以幫助不同的 `PodSet` 區分屬於自己所創建（管理）的 Pods 有哪些。

最後一行的 `ctrl.SetControllerReference` 將 `pod` 的 Owner 綁定成傳入的 `podSet`。

接著，返回 `Reconcile` 函數的部分，先取得現在 `PodSet` 所擁有的，並且正在運行的 Pods：

```go
// Get all pods with label app=podSet.Name
podList := &corev1.PodList{}
labelSet := labels.Set{
  "app":       "podset",
  "podset_cr": podSet.Name, // podSet.ObjectMeta.Name
}
if err := r.List(ctx, podList, &client.ListOptions{
  Namespace:     req.Namespace, // req.NamespacedName.Namespace
  LabelSelector: labels.SelectorFromSet(labelSet),
}); err != nil {
  log.Error(err, "Failed to list pods.")
  return ctrl.Result{}, err
}
```

可以看到，利用 `labelSet := labels.Set{"app": "podset", "podset_cr": podSet.name}`，再使用 `r.List` 的 `opts` `LabelSelector`，可以幫助我們篩選出屬於這個 `podSet` 所擁有的 pods。

取得的 `podList` 中，其中有一些 Pod 可能正在被 terminated（因為 k8s 中，被 elegant deleted by user 的 Pod 只會先將 `DeletionTimestamp` 設上數值而已），因此，利用 Pod 的 `Phase` 以及 `ObjectMeta`，篩選出真正還在運行的 Pod 有哪些。

```go
// Get all running pods
runningPods := []corev1.Pod{}
runningPodNames := []string{}
for _, pod := range podList.Items {
  if pod.ObjectMeta.DeletionTimestamp == nil && (pod.Status.Phase == corev1.PodPending || pod.Status.Phase == corev1.PodRunning) {
    runningPods = append(runningPods, pod)
    runningPodNames = append(runningPodNames, pod.Name)
  }
}
```

如果不做 `pod.ObjectMeta.DeletionTimstamp` 的檢查，雖然 Pod 在被刪除的那個剎那就會呼叫一次 `Reconcile`，但是我們會以為這個 Pod 還在運行中，因爲其 `Status.Phase` 還是 `Running`。

取得 `runningPods` 以及 `runningPodNames` 後，首先更新 `PodSet` 的 Status：

```go
// Update status if needed
if newStatus := (k8stestv1alpha1.PodSetStatus{
  Replicas: int32(len(runningPodNames)),
  PodNames: runningPodNames,
}); !reflect.DeepEqual(podSet.Status, newStatus) {
  podSet.Status = newStatus
  if err := r.Status().Update(ctx, podSet); err != nil {
    log.Error(err, "Failed to update PodSet status")
    return ctrl.Result{}, err
  }
}
```

更新 `podSet.Status` 可以讓我們在其 yaml 中看到 `PodSet` 目前的真實狀態。

注意這裡的 `r.Status().Update` 並不等於 `r.Update`，`r.Update` 更新的是某個 resource 的 spec，而 `r.Status().Update` 是透過 `StatusWriter` 的 `Update` 來更新 resource 的 status。

最後，根據 `runningPods` 的數量，決定要增加或是刪除 Pods。

若 `runningPods` 數量過多，刪除一個 Pod：

```go
// Scale down pods
if int32(len(runningPodNames)) > podSet.Spec.Replicas {
  // Delete a pod once a time
  log.Info("Deleting a Pod in the PodSet", "PodSet.Name", podSet.Name)
  pod := runningPods[0]
  if err := r.Delete(ctx, &pod); err != nil {
    log.Error(err, "Failed to delete pod")
    return ctrl.Result{}, err
  }
  return ctrl.Result{Requeue: true}, nil
}
```

刪除 Pods 的方法採用一次刪除一個，並且回傳 `ctrl.Result{Requeue: true}`，因此下一次的 Reconcile 就會再刪除一個 pod，如果需要的話。

若 `runningPods` 數量不足，增加一個 Pod：

```go
// Scale up pods
if int32(len(runningPodNames)) < podSet.Spec.Replicas {
  // Create a pod once a time
  log.Info("Creating a Pod in the PodSet", "PodSet.Name", podSet.Name)
  pod := r.podForPodSet(podSet)

  if err := r.Create(ctx, pod); err != nil {
    log.Error(err, "Failed to create pod")
    return ctrl.Result{}, err
  }
  return ctrl.Result{Requeue: true}, nil
}
```

使用 `podForPodSet` 以及 `r.Create` 函數來創建一個新的 Pod。

最後完成的程式碼可以在最上面附上的 [Github 連結](https://github.com/justin0u0/podset-operator)查看。

# Build and run the operator

完成程式碼後，首先：

```bash
make install
```

將 CRD 部署到 K8s cluster 中，因此要確認 k8s 這時已經開啟。（如果是使用 Minikube 的話，用 `minikube status` 確認）。

```bash
kubectl get crds

...
podsets.k8stest.justin0u0.com         2021-02-01T09:14:40Z
...
```

這時應該可以看到 CRD 已經被部署到 k8s cluster 中。

測試 Controller 時，可以使用以下兩種方法：

## Run controller locally outside k8s cluster

```bash
make run ENABLE_WEBHOOKS=false
```

可以看到 Controller 已經 Run 在 local。

## Run controller as Deployment inside k8s cluster

要將 controller 變成 Deployment 資源跑在 k8s 內，需要將 operator 打包成 Image。

若是使用 DockerHub 的話，首先確認已經 Login 到 Docker 帳號中：

```bash
docker login
...
Login Succeeded
```

接著打包 Image：

```bash
export USERNAME=<your-docker-username>
make docker-build IMG=$USERNAME/podset-operator:v0.0.1
```

完成後可以看到 image 已經被創建並且打上 tag：

```bash
docker images | grep "podset-operator"

justin0u0/podset-operator                    v0.0.1           8daebb3f17d9   26 hours ago     50.8MB
```

接著，將 Image push 到 container registry 中：

```bash
make docker-push IMG=$USERNAME/podset-operator:v0.0.1
```

最後 deploy 到 k8s cluster 中：

```bash
make deploy IMG=$USERNAME/podset-operator:v0.0.1
```

```bash
kubectl get all -n podset-operator-system

NAME                                                      READY   STATUS    RESTARTS   AGE
pod/podset-operator-controller-manager-6b4f8577db-2bhs8   2/2     Running   0          33m

NAME                                                         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/podset-operator-controller-manager-metrics-service   ClusterIP   10.105.209.249   <none>        8443/TCP   33m

NAME                                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/podset-operator-controller-manager   1/1     1            1           33m

NAME                                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/podset-operator-controller-manager-6b4f8577db   1         1         1       33m
```

# Test Controller

首先將 `config/samples/k8stest_v1alpha1_podset.yaml` 改成以下：

```yaml
apiVersion: k8stest.justin0u0.com/v1alpha1
kind: PodSet
metadata:
  name: podset-sample
spec:
  # Add fields here
  replicas: 2
```

並將 `PodSet` resource 部署到 k8s cluster：

```bash
kubectl -k ./config/samples/.
# or
kubectl apply -f ./config/samples/k8stest_v1alpha1_podset.yaml
```

完成後，一個 `name=podset-sample` 的 `PodSet` 資源會被部署到 `default` 的 namespace 中，並且應該可以看到兩個 Pod 已經在 `default` namespace 中被創建中：

```bash
NAME                         READY   STATUS    RESTARTS   AGE
podset-sample-c8y38qggtxu0   1/1     Running   0          46m
podset-sample-c8y3emmy8qzo   1/1     Running   0          38m
```

可以嘗試將其中一個 pod 刪除、將 `PodSet` Spec 的 `replicas` 修改並 Apply...，應該可以看到 `podset-sample` 的 pods 也會動態的增減。

或是嘗試將 `PodSet` 刪除，可以看到所有的 pods 也會跟著被刪除。

# Cleanup

若是將 controller 部署在 k8s-cluster 中，可以執行：

```bash
make undeploy
```

來刪除所有部署的資源。

# References

[https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/](https://sdk.operatorframework.io/docs/building-operators/golang/tutorial/)

[https://blog.csdn.net/yjk13703623757/article/details/103733253?utm_medium=distribute.pc_relevant.none-task-blog-searchFromBaidu-6.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-searchFromBaidu-6.control](https://blog.csdn.net/yjk13703623757/article/details/103733253?utm_medium=distribute.pc_relevant.none-task-blog-searchFromBaidu-6.control&depth_1-utm_source=distribute.pc_relevant.none-task-blog-searchFromBaidu-6.control)

[https://github.com/operator-framework/operator-sdk/blob/v1.2.0/testdata/go/memcached-operator/controllers/memcached_controller.go](https://github.com/operator-framework/operator-sdk/blob/v1.2.0/testdata/go/memcached-operator/controllers/memcached_controller.go)

[https://pkg.go.dev/github.com/kubernetes-sigs/controller-runtime](https://pkg.go.dev/github.com/kubernetes-sigs/controller-runtime)
