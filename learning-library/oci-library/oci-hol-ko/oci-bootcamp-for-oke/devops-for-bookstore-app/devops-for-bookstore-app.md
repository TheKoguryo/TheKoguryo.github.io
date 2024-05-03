# Deploy the Bookstore App with CI/CD

## Introduction

개발 생산성 향상을 위해 지속적인 빌드 통합, 배포를 위해 CI/CD 툴을 사용합니다. OCI DevOps 서비스는 OCI에서 제공하는 CI/CD 서비스로 소스 코드 관리를 위한 Repository 부터 CI/CD를 위한 파이프라인 구성을 지원합니다.

예상 시간: 60 분

### 목표

* Git Repository 사용하기
* DevOps 서비스를 통한 CI/CD 파아프라인 구성하기

### 전제 조건

아래와 같이 코드 개발을 위한 툴이 필요합니다. 간단한 앱 개발로 여기서는 편의상 사전에 툴들이 설치된 Cloud Shell에서 진행하겠습니다.

* Git CLI

## Task 1: DevOps 서비스 사용을 위한 IAM Policy 설정 (X)

DevOps 서비스를 사용하기 위해서는 DevOps 자원들에 권한 설정이 필요합니다. 공식 문서를 참조하여 권한 설정을 위한 Dynamic Group 및 Group에 대한 Policy를 설정합니다.

- 참고
    * [DevOps IAM Policies](https://docs.oracle.com/en-us/iaas/Content/devops/using/devops_iampolicies.htm#policy-examples)

아래 Dynamic Group 및 Policy는 위 문서의 예제를 기준으로 작성한 내용으로 요구사항에 따라 일부 변경이 될 수 있습니다.

### *Dynamic Group 만들기*

*Dynamic Group 생성은 관련 OCI IAM 권한이 필요합니다. 권한이 없는 경우 관리자 또는 워크샵 진행자에게 요청하거나, 제공하는 Dynamic Group을 사용합니다.*

주어진 Compartment 내에서 DevOps 서비스를 사용할 수 있도록 Compartment에 대한 Dynamic Group을 먼저 생성합니다.

1. Oracle Cloud 콘솔에 로그인합니다.

2. 좌측 상단 햄버거 메뉴에서 **Identity & Security** &gt; **Identity** &gt; **Compartments**로 이동합니다.

3. DevOps 서비스를 사용할 Compartment로 이동하여 OCID를 복사해 둡니다.

4. (**Domain** > **Default Domain** 선택후) **Identity** &gt; **Dynamic Groups**로 이동합니다.

5. **Create Dynamic Group**을 클릭합니다.

6. 복사해둔 Compartment OCID를 이용해 필요한 Dynamic Group을 만듭니다.

    - Name: DevOpsDynamicGroup
    - Rule 설정
        * 모든 규칙 만족 - Match all rules defined below
        * Rule 1
            ```
            <copy>
            Any {resource.type = 'devopsdeploypipeline', resource.type = 'devopsbuildpipeline', resource.type = 'devopsrepository', resource.type = 'devopsconnection'}
            </copy>
            ```
    
        * Rule 2 - compartmentOCID를 복사해둔 OCID로 대체
            ```
            <copy>
            Any {resource.compartment.id = 'compartmentOCID'}
            </copy>
            ```

### DevOps 서비스를 위한 Policy 설정하기

*서비스를 사용하기 위한 권한을 설정합니다. 테넌시 기준의 Policy를 포함하고 있기 때문에 관리자로 로그인하여 수행하여야 합니다.*

1. **Identity** > **Policies** 을 선택합니다.

2. **Create Policy** 클릭

3. 생성할 Policy를 다음과 같이 설정합니다.

    - Name: 예, devops-policy
    - Description: 예, Policy for DevOps for oci-hol-*xx* compartment
    - Compartment: **root compartment**를 선택

4. **Show manual editor** 슬라이딩 버튼을 눌러 매뉴얼 편집 모드로 변경한 다음, 아래 규칙을 추가합니다.

    - `<group-name>`을 적용할 사용자 그룹으로 변경합니다. 예, 'Default'/'DevOpsDynamicGroup'
    - `<compartment-name>`을 적용할 Compartment 이름 변경합니다. 예, oci-hol-*xx*

        ```
        <copy>
        Allow dynamic-group <group-name> to manage devops-family in compartment <compartment-name>
        Allow dynamic-group <group-name> to read secret-family in compartment <compartment-name>
        Allow dynamic-group <group-name> to use ons-topics in compartment <compartment-name>
        Allow dynamic-group <group-name> to manage repos in compartment <compartment-name>
        Allow dynamic-group <group-name> to manage generic-artifacts in compartment <compartment-name>
        Allow dynamic-group <group-name> to use ons-topics in compartment <compartment-name>
        Allow dynamic-group <group-name> to read all-artifacts in compartment <compartment-name>
        Allow dynamic-group <group-name> to manage cluster in compartment <compartment-name>   
        Allow dynamic-group <group-name> to manage repos in tenancy

        # private access setup
        Allow dynamic-group <group-name> to use subnets in compartment <customer-subnet-compartment>
        Allow dynamic-group <group-name> to use vnics in compartment <customer-subnet-compartment>
        </copy>
        ```

6. **Create**를 클릭하여 생성합니다.


## Task 2: DevOps 프로젝트 만들기

### Notification Topic 만들기

DevOps 파이프 라인 실행이 발생하는 주요 이벤트를 알려주기 위한 용도로 Notification Topic 설정이 필요합니다.  DevOps 프로젝트 생성시 필수 요구 사항이라 미리 만듭니다

1. 좌측 상단 햄버거 메뉴에서 **Developer Services** &gt; **Application Integration** &gt; **Notifications**으로 이동합니다.

2. **Create Topic**을 클릭하여 Topic을 생성합니다.

    - Name: 예, oci-hol-*xx*-devops-topic

3. Notification을 위해 생성한 Topic 이벤트를 가져갈 Subscription을 일단 생략합니다. 필요시 구성하시면 됩니다.

### DevOps 프로젝트 만들기

1. 좌측 상단 햄버거 메뉴에서 **Developer Services** &gt; **DevOps**로 이동합니다.

2. 프로젝트 생성을 위해 **Projects**로 이동하여 **Create DevOps project**를 클릭합니다.

3. 생성 정보를 입력하여 프로젝트를 만듭니다.

    - **Project name**: 예, oci-hol-*xx*-devops-project
    - **Notification Topic**: 앞서 생성한 Topic 선택

    ![New DevOps Project](images/new-devops-project.png =45%x*)

5. 프로젝트 생성완료

### Enable Logging

> 프로젝트 생성 직후 Enable Logging 관련 정보 문구가 보이는 것을 볼 수 있습니다. 설명에서 보는 것 처럼 Logging을 활성화하지 않을 경우, 파이프라인 실행 화면에서 오른쪽에 보이는 실행 로그가 안보입니다. 그래서 Enable Logging은 필수입니다. 
    ![Build Run Result](images/build-run-result.png)

1. Project Overview에서 Enable Log을 클릭하거나 왼쪽 메뉴에서 Logs를 클릭합니다.

    ![Enable Logging](images/enable-logging.png =60%x*)

2. 로그를 활성화 버튼을 토글합니다.

    ![Enable Logging](images/enable-logging-2.png =60%x*)

3. 대상 Compartment에 이미 Log Group이 있는 경우 나열된 것 중에 선택이 가능합니다. 처음인 경우 기본값인 *Auto-create a default Log Group*을 사용합니다. 기본 생성 정보를 확인후 **Enable Log** 버튼을 클릭합니다.

    ![Enable Log](images/devops-enable-log.png =50%x*)


## Task 3: Code Repository를 사용하여 애플리케이션 코드 관리하기

1. 코드 저장소 생성을 위해 왼쪽 메뉴에서 **Code Repositories**를 클릭합니다.

2. **Create repository**를 클릭하여 저장소를 만듭니다. 생성된 코드 저장소는 일반적인 Git Repository입니다.

    - Repository name: 예, bookstore-service-code-repo

3. Cloud Shell을 실행합니다.

4. 앞써 개발한 bookstore-service 폴더로 이동합니다.

5. 기존 .git 정보를 삭제하고 다시 초기화합니다.

    ```
    <copy>
    rm -rf .git
    cd complete/
    git init
    git add .
    git commit -m "init"
    git branch -m master main    
    </copy>
    ```

6. Cloud Shell에서 처음 Git을 사용하는 경우 push 하기 전이 아래처럼 사용자정보를 설정합니다.

    ````
    <copy>
    git config --global user.email "you@example.com"
    git config --global user.name "Your Name"
    </copy>
    ````

    예시
    ````
    <copy>
    git config --global user.email "kildong@example.com"
    git config --global user.name "kildong"
    </copy>
    ````    

7. GIT URL을 HTTPS로 사용하는 경우 매번 인증이 필요합니다. 이를 줄이기 위해 아래처럼 인증 정보를 저장 또는 캐쉬하도록 설정합니다.

    - 방법 #1
    ````
    <copy>
    git config credential.helper store
    </copy>
    ````

    - 방법 #2
    ````
    <copy>
    git config --global credential.helper cache

    # 캐시 유효기간을 10시간=36000초로 변경
    git config --global credential.helper 'cache --timeout=36000'
    </copy>
    ````

8. 생성된 코드 저장소로 이동하여, Git URL을 확인합니다.

    ![GIT URL](images/git-url-1.png =30%x*)
    ![GIT URL](images/git-url-2.png =50%x*)

9. 복사한 주소로 Remote Repository로 설정합니다.

    ````
    git remote add origin <Your-Clone-with-HTTPS-URL>
    ```

    - 실행예시

    ```
    git remote add origin https://devops.scmservice.ap-seoul-1.oci.oraclecloud.com/namespaces/axjowrxaexxx/projects/oci-hol-xx-devops-project/repositories/bookstore-service-code-repo
    ```

10. 새 DevOps Code Repository로 변경사항을 푸쉬합니다

    ```
    <copy>
    git fetch   
    git branch --set-upstream-to=origin/main main
    git pull --rebase
    
    git push
    </copy>
    ```

    - 이때 사용자 인증이 필요합니다. "Clone with HTTPS"는 사용자 인증시 아래 유저명 형식과 AuthToken을 사용합니다. 
    - 인증 Username: `<TENANCY_NAME>/<USER_NAME>` 형식
        * `<TENANCY_NAME>`: OCI 서비스 콘솔에서 유저 Profile에서 보이는 *Tenancy:* 에 보이는 이름
            * Docker CLI로 OCIR에 로그인시 사용한 *TENANCY_NAMESPACE가 아닙니다.*
            ![Tenancy Name](images/tenancy-name.png)
        * `<USER_NAME>`: OCI 서비스 콘솔에서 유저 Profile에서 보이는 Identity Domain 이름을 포함한 유저명        
            * 예, default/kildong@example.com            
 
    - AuthToken: OCIR때 사용한 AuthToken을 그대로 사용합니다.

11. Push가 완료되면 아래와 같이 Code Repository에 코드가 반영되어 있습니다. 

    ![Code Repository](images/bookstore-service-code-repo.png)

12. 이후 실습에서 개발 코드를 변경하여 Code Repository에 반영하면, 컨테이너 앱이 재배포 되도록 CI/CD 파이프라인을 생성할 예정입니다.


## Task 4: Build Pipeline 만들기

### Build Pipeline 만들기

CI/CD 중에 코드를 빌드하여 배포 산출물을 만드는 CI 과정에 해당되는 부분을 Build Pipeline을 통해 구성이 가능합니다.

1. **DevOps 프로젝트 페이지**로 이동하여 왼쪽 메뉴의 **Build Pipelines**으로 이동합니다.

2. **Create build pipeline**을 클릭하여 파이프라인을 생성합니다.

    - Name: 예, bookstore-service-build-pipeline

3. 생성된 파이프라인에서 Stage를 추가하여 파이프라인 흐름을 구성할 수 있습니다. 캔버스에서 **Add Stage**를 클릭합니다.

4. 제공 Stage

    - **Managed Build**: 빌드스펙에 정의된 내용에 따라 빌드 과정을 실행합니다.
    - **Delivery Artifacts**: 빌드 산출물(예, 컨테이너 이미지)를 Artifact Repository에 저장합니다.
    - **Trigger Deployment**: 빌드가 끝나고 Deployment Pipeline을 호출합니다.
    - **Wait**: 일정시간 대기합니다.
    ![Build Available Stage](images/build-available-stage.png)

### Build Stage 만들기

1. 빌드를 위해 먼저 **Managed Build** Stage를 추가합니다.

2. Managed Build Stage 설정

    - **Stage name**: 예, build-stage
    - Build Runner Shape: 기본값 선택

        ![Build Stage](images/build-stage-1.png)

    - Connect to your tenancy subnet: Private 접근이 필요한 MySQL, Redis 클러스터에 대해서 빌드 테스트시 연결을 위해 추가 설정합니다.

        ![Build Stage](images/build-stage-2.png)

    - **Build Spec File Path**: 빌드 스크립트 경로를 지정합니다. 따로 설정하지 않으면, 기본적으로 소스 루트에 있는 build_spec.yaml을 파일을 사용합니다.
    - **Primary Code Repository**: 빌드할 메인 소스가 있는 코드 저장소를 지정합니다.

        * OCI Code Repository 유형에서 앞서 만든 Code Repository(예, bookstore-service-code-repo)를 선택
    
        ![Build Stage](images/build-stage-3.png)

3. 설정된 Stage를 **Add**를 클릭하여 추가합니다.

4. 아래 예시와 같이 소스 코드 변경시 빌드 파이프라인은 수행하기 위해서는 Build Spec 정의가 필요합니다.

    - Cloud Shell로 돌아갑니다.

    - 소스 코드 폴더(bookstore-service-code-repo)에 build_spec.yaml 파일을 다음과 같이 정의하고 코드 저장소에 저장합니다.
        * 참조 문서 - https://docs.oracle.com/en-us/iaas/Content/devops/using/build_specs.htm

    - build_spec.yaml
    
        ```
        <copy>
        version: 0.1
        component: build
        timeoutInSeconds: 6000
        shell: bash
        env:
          variables:
            appName: "bookstore-service"    
            "JAVA_HOME" : "/usr/lib64/graalvm/graalvm-java17"
          exportedVariables:
            - OCIR_PATH
            - TAG
            - APP_NAME
        
        steps:
          - type: Command
            name: "Init exportedVariables"
            timeoutInSeconds: 4000
            command: |
              APP_NAME=$appName
              echo $APP_NAME   
        
          - type: Command
            name: "Install the latest Oracle GraalVM for JDK 17 - JDK and Native Image"
            command: |
              yum -y install graalvm-17-native-image
              
          - type: Command
            name: "Set the PATH here. JAVA_HOME already set in env > variables above."
            command: |
              export PATH=$JAVA_HOME/bin:$PATH      
        
          - type: Command
            name: "Build Source"
            timeoutInSeconds: 4000
            command: |
              ./mvnw clean package
        
          - type: Command
            name: "Define Image Tag - Commit ID"
            timeoutInSeconds: 30
            command: |
              COMMIT_ID=`echo ${OCI_TRIGGER_COMMIT_HASH} | cut -c 1-7`
              BUILDRUN_HASH=`echo ${OCI_BUILD_RUN_ID} | rev | cut -c 1-7`
              [ -z "$COMMIT_ID" ] && TAG=$BUILDRUN_HASH || TAG=$COMMIT_ID
        
          - type: Command
            name: "Define OCIR Path"
            timeoutInSeconds: 30
            command: |
              if [ -n "${REPO_NAME_PREFIX}" ] ; then
                  REPO_NAME=$REPO_NAME_PREFIX/$APP_NAME
              else
                  REPO_NAME=$APP_NAME
              fi
        
              if [ -n "$COMPARTMENT_ID" ] ; then
                  oci artifacts container repository create --display-name $REPO_NAME --compartment-id $COMPARTMENT_ID
              fi
        
              TENANCY_NAMESPACE=`oci os ns get --query data --raw-output`
              OCIR_PATH=$OCI_RESOURCE_PRINCIPAL_REGION.ocir.io/$TENANCY_NAMESPACE/$REPO_NAME
        
          - type: Command
            timeoutInSeconds: 400
            name: "Containerize"
            command: |
              export DOCKER_BUILDKIT=1
              docker build -t new-generated-image .
              docker images
        
          - type: Command
            name: "Check exportedVariables"
            timeoutInSeconds: 30
            command: |  
              [ -z "$APP_NAME" ] && APP_NAME=unknown          
              [ -z "$OCIR_PATH" ] && OCIR_PATH=unknown    
              [ -z "$TAG" ] && TAG=unknown
              echo "APP_NAME: " $APP_NAME      
              echo "OCIR_PATH: " $OCIR_PATH
              echo "TAG: " $TAG
        
        outputArtifacts:
          - name: output-image
            type: DOCKER_IMAGE
            location: new-generated-image
        
        </copy>          
        ```

    - 생성한 build_spec.yaml을 Code Repository에 반영합니다.

        ````
        <copy>
        git add build_spec.yaml
        git commit -m "add build_spec.yaml"
        git push
        </copy>
        ````

5. 빌드 파이프라인 화면으로 돌아갑니다.

6. **Parameters** 탭으로 이동하여, 아래 값을 입력합니다. build_spec에서 사용하는 디폴트값을 아래와 같이 입력할 수 있습니다.

    - `REPO_NAME_PREFIX`: 예, `oci-hol-xx`

        * 다른 사람과 충돌되지 않게 할당받은 Compartment Name을 입력합니다.
        * 그러면, build_spec.yaml 상에서 사용하는 OCIR Repository 이름은 $`REPO_NAME_PREFIX`/$`APP_NAME`이 됩니다. 예, `oci-hol-xx/bookstore-service`

    ![Build Spec Parameters](images/build-pipeline-parameters.png)

7. **Build pipeline** 탭으로 이동하여 오른쪽 위 **Start Manual Run** 버튼을 클릭하여 파이프라인을 실행합니다.

8. **Build run** 탭에서 실행 결과를 확인합니다. 아래와 같이 build_spec.yaml에 정의한 스크립트가 수행됩니다.

    ![Build Run Result](images/build-run-result-2.png)

9. ExportedVariables 확인

    실행 결과 화면에서 오른쪽 위 점3개를 클릭하여 상세 화면(View details)으로 이동합니다. Build Output 탭에서 실행결과로 나온 변수값을 볼 수 있습니다. 이 변수들은 이후 Stage 또는 연결되어 호출된 Deployment Pipeline으로 전달되어 사용할 수 있습니다.

    ![ExportVariables](images/build-output.png =60%x*)

### 컨테이너 이미지 OCIR 등록 Stage 만들기

1. Build Pipeline 탭으로 이동합니다.

2. 플러스 버튼을 클릭하여 build-stage 다음에 stage를 추가합니다.

   ![OCIR Stage](images/ocir-stage-1.png)

3. **Delivery Artifacts Stage** 유형을 선택합니다.

4. stage 이름을 입력하고 Create Artifact를 클릭합니다.

    - Name: 예, `deliver-generated-image`

   ![OCIR Stage](images/ocir-stage-2.png)

5. Container Image Repository 유형의 Artifact를 추가하는 과정입니다.

    - Name: `generated_image_with_tag`
    - Artifact source: `${OCIR_PATH}:${TAG}`

        * docker push 명령으로 이미지를 푸쉬할 경로를 지정하는 것으로 생각하면 됩니다. 하드 코딩해도 되지만 여기서는 build-stage에서 넘어온 exportedVariable들을 사용합니다.

    ![Add Artifact](images/add-artifact-1.png =60%x*)

6. Artifact 매핑

    - Associate Artifact에서 방금 추가한 1개의 Artifact에 실제 컨테이너 이미지 파일을 매핑해 줍니다. 앞서 build-stage에서 build_spec.yaml에서 정의한 outputArtifacts 상의 이름을 입력합니다.

        ```
        outputArtifacts:
          - name: output-image
            type: DOCKER_IMAGE
            location: new-generated-image 
        ```

        ![Associate Artifacts](images/associate-artifacts-2.png =55%x*)

8. 아래쪽 **Add** 버튼을 클릭하여, 이제 delivery stage을 추가 완료합니다.

9. 파이프라인을 다시 실행해 봅니다. 

10. 이제 실제 소스코드로 빌드된 컨테이너 이미지가 OCIR에 자동으로 등록됩니다.

    ![Pushed Image](images/pushed-image.png)



## Task 5: Deploy Pipeline 만들기

### Deploy Pipeline 만들기

CI/CD 중에 빌드된 산출물을 가지고 실제 서버에 배포하는 CD 과정에 해당되는 부분을 Deployment Pipeline을 통해 구성이 가능합니다.

1. **DevOps 프로젝트 페이지**로 이동하여 왼쪽 메뉴의 **Deployment Pipelines**로 이동합니다.

2. **Create pipeline**을 클릭하여 파이프라인을 생성합니다.

    - Name: 예, bookstore-service-deployment-pipeline

3. 생성된 파이프라인에서 **Add Stage**를 클릭하여 Stage를 추가합니다.

4. 제공 Stage

    - **Deploy**: OKE, Compute 인스턴스 배포, Oracle Function에 배포 기능을 제공합니다.
    - **Control**: 승인 대기, 트래픽 변경, 대기 등을 지원합니다.
    - **Integration**: 커스텀 로직 수행을 위한 Oracle Function 또는 쉘스크립트 실행을 지원합니다.

    ![Deployment Add Stage](images/deployment-add-stage.png)

5. 배포할 manifest 파일을 먼저 생성해야 합니다. 취소하고 다음으로 넘어갑니다.

### Kubernetes에 배포할 manifest 파일 준비

Kubernetes에 배포할 Stage 유형을 사용하기 위해서는 사전에 배포할 manifest yaml 파일을 준비해야 합니다.

1. **DevOps 프로젝트 페이지**로 이동하여 왼쪽 메뉴의 **Artifacts**로 이동합니다.

2. Artifacts로 앞서 빌드 파이프라인 만들때 등록한 1개가 있는 것을 볼수 있습니다. 여기에 등록된 Artifact는 재사용이 가능합니다.

    ![Artifacts](images/artifacts.png)

3. manifest 파일을 등록하기 위해 Add artifact를 클릭합니다.

4. 등록 유형 중에서 **Kubernetes manifest**를 선택합니다.

    ![Kubernetes Manifest Type](images/k8s-manifest-type.png)

5. Kubernetes manifest 유형에는 Artifact Source로 2가지 유형을 지원합니다.

    - Artifact Registry Repository: OCI Artifact Registry를 서비스에 있는 자원을 참조할 경우에 선택합니다.
    - Inline: 인라인은 현재 DevOps 프로젝트에 있는 여기 Artifact에 직접 입력하는 것을 말합니다.

6. Artifact Source로 Inline 유형으로 다음과 같이 등록합니다.

    - Name: 예, `bookstore-service.yaml`

        ![K8S Deployment Manifest](images/k8s-deployment-template.png =45%x*)

    - Value

        build-stage 실행결과 중에서 exportedVariables를 사용하도록, 이전 실습에서 배포시 사용한 yaml 파일에서 Image URL만 build-stage에서의 결과값을 사용하도록 수정된 내용입니다. 아래 내용을 복사해 그대로 사용하면 됩니다.

        ```
        <copy>
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          labels:
            app: bookstore-service
          name: bookstore-service-deployment
        spec:
          replicas: 1
          selector:
            matchLabels:
              app: bookstore-service
          template:
            metadata:
              labels:
                app: bookstore-service
            spec:
              containers:
              - name: bookstore-service
                image: ${OCIR_PATH}:${TAG}
              imagePullSecrets:
              - name: ocir-secret
        ---
        apiVersion: v1
        kind: Service
        metadata:
          name: bookstore-service-service
          annotations:
            oci.oraclecloud.com/load-balancer-type: "lb"
            service.beta.kubernetes.io/oci-load-balancer-shape: "flexible"
            service.beta.kubernetes.io/oci-load-balancer-shape-flex-min: "10"
            service.beta.kubernetes.io/oci-load-balancer-shape-flex-max: "10"
            service.beta.kubernetes.io/oci-load-balancer-backend-protocol: "HTTP"        
        spec:
          selector:
            app: bookstore-service
          ports:
            - protocol: TCP
              port: 80
              targetPort: 8080
          type: LoadBalancer
        </copy>        
        ```

7. Cloud Shell로 돌아가 배포될 default namespace에 ocir-secret을 이전 실습에서 이미 만든 것을 그대로 사용합니다. 없는 경우 다시 생성합니다.

    ````
    <copy>
    kubectl create secret generic ocir-secret \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson -n default
    </copy>
    ````

### Kubernetes Environment 등록하기

1. **DevOps 프로젝트 페이지**로 이동하여 왼쪽 메뉴의 **Environments**로 이동하여 배포할 OKE 환경을 등록합니다.

2. OKE 유형을 선택합니다.

    - Name: 클러스터 이름 예, oke-cluster-1

    ![Create Environment](images/create-environment.png =70%x*)

3. 배포할 클러스터를 선택합니다.

    ![Target OKE Cluster](images/oke-environment.png =50%x*)

   
### Kubernetes manifest 배포 Stage 만들기

1. 등록한 Deployment Pipeline 설정 페이지로 이동합니다.

2. **Add Stage**를 클릭하여 **Apply manifest to your Kubernetes cluster** Stage를 추가합니다.

3. 배포할 환경을 선택합니다.

4. 배포할 manifest 파일을 선택합니다

    - Name: 예, apply-manifest-to-oke-stage

    ![Select Manifest](images/deploy-to-oke-1.png =70%x*)

5. 파이프라인 완성

    ![Completed Pipeline](images/deploy-to-oke-2.png =30%x*)



### Build Pipeline에서 Deployment Pipeline 호출하기

앞서 만든 Build Pipeline에서 컨테이너 이미지 까지 OCIR에 등록하고 나면, OKE에 배포할 Deployment Pipeline을 기동되어야 빌드에서 배포까지가 완료됩니다. 이제 Deployment Pipeline을 등록하였으므로, Build Pipeline에서 호출할 수 있습니다.

1. 앞서 만든 **Build Pipelines**으로 이동합니다.

2. 파이프라인 마지막에 Stage를 추가합니다.

3. **Trigger Deployment** 유형을 선택합니다.

4. 설정한 Deployment Pipeline을 지정합니다.

    - Name: 예, trigger-deployment-stage

   ![Deployment Pipeline](images/trigger-deployment-pipeline.png)

5. 전체 흐름이 완료되었습니다.

   ![Deployment Pipeline Completed](images/deployment-pipeline-completed.png)


### Trigger 설정하기

지금 까지는 테스트를 하기 위해 Build Pipeline에서 Start Manual Run을 통해 시작하였습니다. 실제로는 개발자가 코드를 코드 저장소에 반영이 될 때 자동으로 빌드, 배포 파이프라인이 동작할 필요가 있습니다. Trigger는 코드 저장소에 발생한 이벤트를 통해 빌드 파이프라인을 시작하게 하는 역할을 하게 됩니다.

1. **DevOps 프로젝트 페이지**로 이동하여 왼쪽 메뉴의 **Triggers**로 이동합니다.

2. **Create trigger**을 클릭합니다.

3. Trigger를 설정합니다.

    - **Name**: 예, bookstore-service-trigger
    - **Source Code Repository**: OCI Code Repository를 포함하여, 여러 유형의 Git Repository 연동을 지원합니다. 예제에서는 앞서 만든 OCI Code Repository상의 bookstore-service-code-repo를 선택합니다.
    - **Actions**: 트리거링 되었을 때 호출하는 액션으로 작성한 빌드 파이프라인인 bookstore-service-build-pipeline을 선택합니다.
 
        ![Create Trigger](images/create-trigger.png =60%x*)

4. 설정된 내용으로 Trigger를 생성합니다.


## Task 6: 작성한 전체 CI/CD 파이프라인 테스트하기

응답 메시지 중 일부를 변경하는 요청사항이 있다는 가정하에, 소스 코드를 변경하고, Code Repository에 반영하여, CI/CD 파이프라인이 실행되게 합니다.

- 수정 전
    
    ![Get Books Before](images/bookstore-service-reponse-before.png =50%x*)

- 수정사항: 위 두 count 항목을 응답 메시지에서 제외합니다.

### 방법 #1. Cloud Shell에서 코드변경하기

1. Cloud Shell를 실행합니다.

2. Cloud Shell에서 src/main/java/com/example/bookstore/entities/Book.java 파일을 변경합니다.

    응답메시지에서 제외되도록 @JsonIgnore annotation을 두 멤버변수 앞에 추가합니다.

    ````
    ...

    @JsonIgnore
    private int ratings_count;
    @JsonIgnore
    private int text_reviews_count;

    ...    
    ````

3. 코드를 Code Repository에 Push 합니다.

    ````
    <copy>    
    git add .
    git commit -m "add JsonIgnore to count fields"
    git push
    </copy>
    ````

### 방법 #2. Cloud Editor에서 코드변경하기

1. Cloud Editor를 실행합니다.

    ![Code Editor](images/code-editor-start.png =40%x*)

2. 메뉴에서 **File** &gt; **Open** 을 통해 bookstore-service 폴더를 엽니다.

3. 열린 폴더안의 src/main/java/com/example/bookstore/entities/Book.java 파일을 변경합니다.

    응답메시지에서 제외되도록 @JsonIgnore annotation을 두 멤버변수 앞에 추가합니다.
    ![Code Editor - OpeningHours](images/code-editor-books.png)

5. 왼쪽 메뉴에서 Source Control로 이동하여, 변경사항을 스테이지합니다.
    ![Code Editor - OpeningHours](images/code-editor-stage-all-changes.png)

6. 코멘트(예, update opening-hours) 추가하고, 스테이지된 변경사항을 커밋합니다.     
    ![Code Editor - OpeningHours](images/code-editor-commit.png)

7. DevOps Code Repository로 반영하기 위해 왼쪽 아래의 Push 아이콘을 클릭합니다.    
    ![Code Editor - OpeningHours](images/code-editor-push-commit.png)

8. 확인 창이 뜨면 OK를 클릭합니다.    
    ![Code Editor - OpeningHours](images/code-editor-push-ok.png)


### DevOps 파이프라인 실행결과 확인

1. DevOps 프로젝트 화면으로 이동합니다.

2. 빌드 실행(Build History) 내역을 보면, 그림과 같이 Trigger 되어 실행된 것을 볼수 있습니다. 액션메뉴에서 상세내역을 확인합니다.

    ![Pipeline Test Result](images/pipeline-test-1.png)

3. Trigger 탭에서 Commit ID를 볼 수 있으며, Code Repository와 링크되어 있습니다.

    ![Pipeline Test Result](images/pipeline-test-2.png)

4. Commit ID를 클릭하면 Code Repository상의 코드 변경 분을 확인할 수 있습니다.

    ![Pipeline Test Result](images/pipeline-test-3.png)

5. 빌드 실행(Build History) 내역으로 돌아가 보면, 빌드 파이프라인이 정상적으로 코드 빌드 부터 컨테이너 이미지 생성, 배포 파이프라인 호출까지 실행되었습니다.

    ![Pipeline Test Result](images/pipeline-test-4.png)

6. 배포 파이프라인도 정상 실행되었습니다.

    ![Pipeline Test Result](images/pipeline-test-5.png)

7. OKE 클러스터를 조회해 보면 정상 배포 되었습니다.


    Pod가 새롭게 배포되었고, 이미지 주소가 새로 생성된 것으로 태그가 Commit ID와 동일함을 알수있습니다.
    ```
    $ kubectl get pod
    NAME                                            READY   STATUS    RESTARTS   AGE
    bookstore-service-deployment-5447bb749b-xl6t9   1/1     Running   0          6m59s
    
    $ kubectl describe pod bookstore-service-deployment-5447bb749b-xl6t9 | grep image
      Normal  Pulling    7m16s  kubelet            Pulling image "ap-seoul-1.ocir.io/axjowrxaexxx/oci-hol-xx/bookstore-service:2f5c8a4"
      Normal  Pulled     7m12s  kubelet            Successfully pulled image "ap-seoul-1.ocir.io/axjowrxaexxx/oci-hol-xx/bookstore-service:2f5c8a4" in 4.218s (4.218s including waiting)      
    ```

8. 서비스 주소로 접속시 정상 동작을 확인할 수 있습니다.
 
    ![Updated Storefront UI](images/pipeline-test-6.png =50%x*)


이제 **다음 실습을 진행**하시면 됩니다.

## Learn More

* [DevOps Build Specification](https://docs.oracle.com/en-us/iaas/Content/devops/using/build_specs.htm)

## Acknowledgements

- **Author** - DongHee Lee
- **Last Updated By/Date** - DongHee Lee, April 2024
