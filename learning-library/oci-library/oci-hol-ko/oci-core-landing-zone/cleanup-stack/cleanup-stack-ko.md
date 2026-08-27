# 정리

## 소개

실습을 완료한 후에는 OCI Resource Manager(ORM)가 생성한 모든 OCI 리소스를 정리하는 것을 권장합니다. 이 실습에서는 이러한 리소스를 올바르게 삭제하고 Stack을 제거하는 과정을 안내합니다.

예상 시간: 10분

### 목표

- ORM으로 리소스 삭제
- ORM Stack 삭제


## 작업 1: ORM Stack이 생성한 리소스 삭제

1. OCI 콘솔에 로그인합니다.
2. 왼쪽 위의 햄버거 메뉴를 엽니다. **Developer Services**를 클릭한 뒤 **Resource Manager > Stacks**를 선택합니다.

    ![Stacks으로 이동](./images/developer-orm-stacks.png" Stacks으로 이동")

3. Stack을 생성한 컴파트먼트를 선택하면 만든 Stack들이 보입니다.

4. 생성한 역순으로 진행합니다. 모든 실습을 진행했다고 하면, 아래 순서로 진행합니다.

    1. core-landing-zone-main-ap-seoul-1
    2. core-landing-zone-main-workload-1-network
    3. core-landing-zone-main-workload-1-iam
    4. core-landing-zone-main

5. 각 Stack에서 **Destroy**를 클릭하고, 오른쪽 아래에 표시되는 확인 창에서 다시 확인합니다.

6. 작업이 완료될 때까지 기다린 뒤 출력을 검토합니다.


## 작업 2: ORM Stack 삭제

워크숍을 위해 프로비저닝된 모든 리소스를 성공적으로 삭제했으므로, 이제 환경을 원래 상태로 되돌리기 위해 Stack을 안전하게 삭제할 수 있습니다.

1. 왼쪽 위의 breadcrumb 링크를 따라 **Stack Details**를 클릭한 다음, **More Actions > Delete Stack**을 선택합니다.


이것으로 워크샵을 완료합니다.

## 감사의 말 (Acknowledgements)

* **Author:** DongHee Lee
* **Last Updated By/Date:** DongHee Lee, July 2026
