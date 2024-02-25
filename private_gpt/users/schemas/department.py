from typing import List, Optional
from pydantic import BaseModel


class DepartmentBase(BaseModel):
    name: str


class DepartmentCreate(DepartmentBase):
    pass


class DepartmentUpdate(DepartmentBase):
    id: int

class DepartmentDelete(BaseModel):
    id: int



class DepartmentInDB(DepartmentBase):
    id: int
    company_id: int
    total_users: Optional[int]
    total_documents: Optional[int]

    class Config:
        orm_mode = True

class DepartmentAdminCreate(DepartmentBase):
    company_id: int

    class Config:
        orm_mode = True

class Department(BaseModel):
    id: int
    name: str
    total_users: Optional[int]
    total_documents: Optional[int]
    
